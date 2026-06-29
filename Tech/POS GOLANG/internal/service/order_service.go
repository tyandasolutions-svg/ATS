package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

const taxRate = 0.11 // PPN 11%

type OrderService interface {
	Create(ctx context.Context, userID uuid.UUID, req *model.CreateOrderRequest) (*model.Order, error)
	GetByID(ctx context.Context, id uuid.UUID) (*model.Order, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Order, int64, error)
	Cancel(ctx context.Context, id uuid.UUID) error
	Refund(ctx context.Context, id uuid.UUID) error
	GetDailySummary(ctx context.Context, date string) (*repository.DailySummary, error)
	CompleteOrder(ctx context.Context, orderID uuid.UUID) error
}

type orderService struct {
	orderRepo     repository.OrderRepository
	productRepo   repository.ProductRepository
	inventoryRepo repository.InventoryRepository
	customerRepo  repository.CustomerRepository
	logger        *zap.Logger
}

func NewOrderService(
	orderRepo repository.OrderRepository,
	productRepo repository.ProductRepository,
	inventoryRepo repository.InventoryRepository,
	customerRepo repository.CustomerRepository,
	logger *zap.Logger,
) OrderService {
	return &orderService{
		orderRepo:     orderRepo,
		productRepo:   productRepo,
		inventoryRepo: inventoryRepo,
		customerRepo:  customerRepo,
		logger:        logger,
	}
}

func (s *orderService) Create(ctx context.Context, userID uuid.UUID, req *model.CreateOrderRequest) (*model.Order, error) {
	var items []model.OrderItem
	var subtotal float64

	// Validate and calculate items
	for _, item := range req.Items {
		productID, err := uuid.Parse(item.ProductID)
		if err != nil {
			return nil, model.NewValidationError("invalid product ID: " + item.ProductID)
		}

		product, err := s.productRepo.FindByID(ctx, productID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, model.NewNotFoundError("product " + item.ProductID)
			}
			return nil, model.NewInternalError("failed to get product")
		}

		if !product.IsActive {
			return nil, model.NewValidationError("product " + product.Name + " is not active")
		}

		// Check stock
		inventory, err := s.inventoryRepo.FindByProductID(ctx, productID)
		if err != nil || inventory.Quantity < item.Quantity {
			return nil, model.NewValidationError("insufficient stock for " + product.Name)
		}

		itemSubtotal := (product.Price * float64(item.Quantity)) - item.Discount
		subtotal += itemSubtotal

		items = append(items, model.OrderItem{
			ProductID:   productID,
			ProductName: product.Name,
			Quantity:    item.Quantity,
			UnitPrice:   product.Price,
			Discount:    item.Discount,
			Subtotal:    itemSubtotal,
		})
	}

	// Calculate totals
	taxAmount := subtotal * taxRate
	totalAmount := subtotal + taxAmount - req.Discount

	// Generate order number
	orderNumber := generateOrderNumber()

	order := &model.Order{
		OrderNumber:    orderNumber,
		UserID:         userID,
		CustomerName:   req.CustomerName,
		Subtotal:       subtotal,
		TaxAmount:      taxAmount,
		DiscountAmount: req.Discount,
		TotalAmount:    totalAmount,
		Status:         model.OrderStatusPending,
		PaymentMethod:  req.PaymentMethod,
		PaymentStatus:  model.PaymentStatusPending,
		Notes:          req.Notes,
		Items:          items,
	}

	if err := s.orderRepo.Create(ctx, order); err != nil {
		s.logger.Error("failed to create order", zap.Error(err))
		return nil, model.NewInternalError("failed to create order")
	}

	// Reduce inventory
	for _, item := range items {
		if err := s.inventoryRepo.UpdateStock(ctx, item.ProductID, -item.Quantity); err != nil {
			s.logger.Error("failed to reduce stock", zap.String("product_id", item.ProductID.String()), zap.Error(err))
		}

		log := &model.InventoryLog{
			ProductID:      item.ProductID,
			QuantityChange: -item.Quantity,
			Type:           model.InventoryLogTypeOut,
			ReferenceID:    order.ID.String(),
			Notes:          "Order: " + orderNumber,
			CreatedBy:      userID,
		}
		s.inventoryRepo.CreateLog(ctx, log)
	}

	return order, nil
}

func (s *orderService) GetByID(ctx context.Context, id uuid.UUID) (*model.Order, error) {
	order, err := s.orderRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("order")
		}
		return nil, model.NewInternalError("failed to get order")
	}
	return order, nil
}

func (s *orderService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Order, int64, error) {
	query.SetDefaults()
	return s.orderRepo.FindAll(ctx, query)
}

func (s *orderService) Cancel(ctx context.Context, id uuid.UUID) error {
	order, err := s.orderRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("order")
		}
		return model.NewInternalError("failed to get order")
	}

	if order.Status != model.OrderStatusPending {
		return model.NewValidationError("only pending orders can be cancelled")
	}

	order.Status = model.OrderStatusCancelled

	// Restore inventory
	for _, item := range order.Items {
		if err := s.inventoryRepo.UpdateStock(ctx, item.ProductID, item.Quantity); err != nil {
			s.logger.Error("failed to restore stock", zap.Error(err))
		}

		log := &model.InventoryLog{
			ProductID:      item.ProductID,
			QuantityChange: item.Quantity,
			Type:           model.InventoryLogTypeIn,
			ReferenceID:    order.ID.String(),
			Notes:          "Order cancelled: " + order.OrderNumber,
		}
		s.inventoryRepo.CreateLog(ctx, log)
	}

	return s.orderRepo.Update(ctx, order)
}

func (s *orderService) Refund(ctx context.Context, id uuid.UUID) error {
	order, err := s.orderRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("order")
		}
		return model.NewInternalError("failed to get order")
	}

	if order.Status != model.OrderStatusCompleted {
		return model.NewValidationError("only completed orders can be refunded")
	}

	order.Status = model.OrderStatusRefunded
	order.PaymentStatus = model.PaymentStatusRefunded

	// Restore inventory
	for _, item := range order.Items {
		if err := s.inventoryRepo.UpdateStock(ctx, item.ProductID, item.Quantity); err != nil {
			s.logger.Error("failed to restore stock", zap.Error(err))
		}

		log := &model.InventoryLog{
			ProductID:      item.ProductID,
			QuantityChange: item.Quantity,
			Type:           model.InventoryLogTypeIn,
			ReferenceID:    order.ID.String(),
			Notes:          "Order refunded: " + order.OrderNumber,
		}
		s.inventoryRepo.CreateLog(ctx, log)
	}

	return s.orderRepo.Update(ctx, order)
}

func (s *orderService) GetDailySummary(ctx context.Context, date string) (*repository.DailySummary, error) {
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	return s.orderRepo.GetDailySummary(ctx, date)
}

func (s *orderService) CompleteOrder(ctx context.Context, orderID uuid.UUID) error {
	order, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("order")
		}
		return model.NewInternalError("failed to get order")
	}

	if order.Status != model.OrderStatusPending {
		return model.NewValidationError("order is not in pending status")
	}

	order.Status = model.OrderStatusCompleted
	order.PaymentStatus = model.PaymentStatusSuccess

	return s.orderRepo.Update(ctx, order)
}

func generateOrderNumber() string {
	now := time.Now()
	return fmt.Sprintf("POS-%s-%04d", now.Format("20060102"), now.UnixNano()%10000)
}
