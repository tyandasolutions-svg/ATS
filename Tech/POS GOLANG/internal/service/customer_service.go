package service

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type CustomerService interface {
	Create(ctx context.Context, req *model.CreateCustomerRequest) (*model.Customer, error)
	GetByID(ctx context.Context, id uuid.UUID) (*model.Customer, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Customer, int64, error)
	Update(ctx context.Context, id uuid.UUID, req *model.UpdateCustomerRequest) (*model.Customer, error)
	Delete(ctx context.Context, id uuid.UUID) error
	AddPoints(ctx context.Context, id uuid.UUID, amount float64) error
}

type customerService struct {
	customerRepo repository.CustomerRepository
	logger       *zap.Logger
}

func NewCustomerService(customerRepo repository.CustomerRepository, logger *zap.Logger) CustomerService {
	return &customerService{
		customerRepo: customerRepo,
		logger:       logger,
	}
}

func (s *customerService) Create(ctx context.Context, req *model.CreateCustomerRequest) (*model.Customer, error) {
	if req.Email != "" {
		existing, _ := s.customerRepo.FindByEmail(ctx, req.Email)
		if existing != nil {
			return nil, model.NewConflictError("customer with this email already exists")
		}
	}

	customer := &model.Customer{
		Name:  req.Name,
		Email: req.Email,
		Phone: req.Phone,
	}

	if err := s.customerRepo.Create(ctx, customer); err != nil {
		s.logger.Error("failed to create customer", zap.Error(err))
		return nil, model.NewInternalError("failed to create customer")
	}

	return customer, nil
}

func (s *customerService) GetByID(ctx context.Context, id uuid.UUID) (*model.Customer, error) {
	customer, err := s.customerRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("customer")
		}
		return nil, model.NewInternalError("failed to get customer")
	}
	return customer, nil
}

func (s *customerService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Customer, int64, error) {
	query.SetDefaults()
	return s.customerRepo.FindAll(ctx, query)
}

func (s *customerService) Update(ctx context.Context, id uuid.UUID, req *model.UpdateCustomerRequest) (*model.Customer, error) {
	customer, err := s.customerRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("customer")
		}
		return nil, model.NewInternalError("failed to get customer")
	}

	if req.Name != "" {
		customer.Name = req.Name
	}
	if req.Email != "" {
		customer.Email = req.Email
	}
	if req.Phone != "" {
		customer.Phone = req.Phone
	}

	if err := s.customerRepo.Update(ctx, customer); err != nil {
		return nil, model.NewInternalError("failed to update customer")
	}
	return customer, nil
}

func (s *customerService) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := s.customerRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("customer")
		}
		return model.NewInternalError("failed to get customer")
	}
	return s.customerRepo.Delete(ctx, id)
}

func (s *customerService) AddPoints(ctx context.Context, id uuid.UUID, amount float64) error {
	customer, err := s.customerRepo.FindByID(ctx, id)
	if err != nil {
		return model.NewNotFoundError("customer")
	}

	// 1 point per 10.000 spent
	points := int(amount / 10000)
	customer.Points += points
	customer.TotalSpent += amount

	return s.customerRepo.Update(ctx, customer)
}
