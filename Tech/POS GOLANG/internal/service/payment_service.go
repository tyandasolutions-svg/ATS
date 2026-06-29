package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type PaymentService interface {
	ProcessPayment(ctx context.Context, req *model.ProcessPaymentRequest) (*model.Payment, error)
	GetByID(ctx context.Context, id uuid.UUID) (*model.Payment, error)
	HandleCallback(ctx context.Context, req *model.PaymentCallbackRequest) error
	RefundPayment(ctx context.Context, paymentID uuid.UUID) error
}

type paymentService struct {
	paymentRepo repository.PaymentRepository
	orderRepo   repository.OrderRepository
	orderSvc    OrderService
	logger      *zap.Logger
}

func NewPaymentService(
	paymentRepo repository.PaymentRepository,
	orderRepo repository.OrderRepository,
	orderSvc OrderService,
	logger *zap.Logger,
) PaymentService {
	return &paymentService{
		paymentRepo: paymentRepo,
		orderRepo:   orderRepo,
		orderSvc:    orderSvc,
		logger:      logger,
	}
}

func (s *paymentService) ProcessPayment(ctx context.Context, req *model.ProcessPaymentRequest) (*model.Payment, error) {
	orderID, err := uuid.Parse(req.OrderID)
	if err != nil {
		return nil, model.NewValidationError("invalid order ID")
	}

	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("order")
		}
		return nil, model.NewInternalError("failed to get order")
	}

	if order.Status != model.OrderStatusPending {
		return nil, model.NewValidationError("order is not in pending status")
	}

	if req.Amount < order.TotalAmount {
		return nil, model.NewValidationError("payment amount is less than order total")
	}

	payment := &model.Payment{
		OrderID:       orderID,
		PaymentMethod: req.PaymentMethod,
		Amount:        req.Amount,
		Status:        model.PaymentStatusPending,
	}

	// For cash payments, complete immediately
	if req.PaymentMethod == model.PaymentMethodCash {
		payment.Status = model.PaymentStatusSuccess
		now := time.Now().Format(time.RFC3339)
		payment.PaidAt = &now

		if err := s.paymentRepo.Create(ctx, payment); err != nil {
			return nil, model.NewInternalError("failed to create payment")
		}

		// Complete the order
		if err := s.orderSvc.CompleteOrder(ctx, orderID); err != nil {
			s.logger.Error("failed to complete order after cash payment", zap.Error(err))
		}

		return payment, nil
	}

	// For digital payments, create pending payment and return payment info
	// In production, this would integrate with payment gateway (Midtrans/Xendit)
	payment.ReferenceNumber = "PAY-" + uuid.New().String()[:8]

	if err := s.paymentRepo.Create(ctx, payment); err != nil {
		return nil, model.NewInternalError("failed to create payment")
	}

	return payment, nil
}

func (s *paymentService) GetByID(ctx context.Context, id uuid.UUID) (*model.Payment, error) {
	payment, err := s.paymentRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("payment")
		}
		return nil, model.NewInternalError("failed to get payment")
	}
	return payment, nil
}

func (s *paymentService) HandleCallback(ctx context.Context, req *model.PaymentCallbackRequest) error {
	orderID, err := uuid.Parse(req.OrderID)
	if err != nil {
		return model.NewValidationError("invalid order ID")
	}

	payments, err := s.paymentRepo.FindByOrderID(ctx, orderID)
	if err != nil || len(payments) == 0 {
		return model.NewNotFoundError("payment")
	}

	payment := &payments[0]

	switch req.Status {
	case "settlement", "capture":
		payment.Status = model.PaymentStatusSuccess
		now := time.Now().Format(time.RFC3339)
		payment.PaidAt = &now
		payment.ProviderResponse = req.TransactionID

		if err := s.paymentRepo.Update(ctx, payment); err != nil {
			return model.NewInternalError("failed to update payment")
		}

		// Complete the order
		if err := s.orderSvc.CompleteOrder(ctx, orderID); err != nil {
			s.logger.Error("failed to complete order", zap.Error(err))
		}

	case "deny", "cancel", "expire":
		payment.Status = model.PaymentStatusFailed
		payment.ProviderResponse = req.TransactionID

		if err := s.paymentRepo.Update(ctx, payment); err != nil {
			return model.NewInternalError("failed to update payment")
		}
	}

	return nil
}

func (s *paymentService) RefundPayment(ctx context.Context, paymentID uuid.UUID) error {
	payment, err := s.paymentRepo.FindByID(ctx, paymentID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("payment")
		}
		return model.NewInternalError("failed to get payment")
	}

	if payment.Status != model.PaymentStatusSuccess {
		return model.NewValidationError("only successful payments can be refunded")
	}

	payment.Status = model.PaymentStatusRefunded
	if err := s.paymentRepo.Update(ctx, payment); err != nil {
		return model.NewInternalError("failed to refund payment")
	}

	// Refund the order
	if err := s.orderSvc.Refund(ctx, payment.OrderID); err != nil {
		s.logger.Error("failed to refund order", zap.Error(err))
	}

	return nil
}
