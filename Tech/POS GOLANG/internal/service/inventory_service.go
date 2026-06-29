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

type InventoryService interface {
	GetByProductID(ctx context.Context, productID uuid.UUID) (*model.Inventory, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Inventory, int64, error)
	StockIn(ctx context.Context, userID uuid.UUID, req *model.StockInRequest) error
	StockOut(ctx context.Context, userID uuid.UUID, req *model.StockOutRequest) error
	StockAdjustment(ctx context.Context, userID uuid.UUID, req *model.StockAdjustmentRequest) error
	GetAlerts(ctx context.Context) ([]model.Inventory, error)
	GetLogs(ctx context.Context, productID uuid.UUID, query *model.PaginationQuery) ([]model.InventoryLog, int64, error)
}

type inventoryService struct {
	inventoryRepo repository.InventoryRepository
	logger        *zap.Logger
}

func NewInventoryService(inventoryRepo repository.InventoryRepository, logger *zap.Logger) InventoryService {
	return &inventoryService{
		inventoryRepo: inventoryRepo,
		logger:        logger,
	}
}

func (s *inventoryService) GetByProductID(ctx context.Context, productID uuid.UUID) (*model.Inventory, error) {
	inventory, err := s.inventoryRepo.FindByProductID(ctx, productID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("inventory")
		}
		return nil, model.NewInternalError("failed to get inventory")
	}
	return inventory, nil
}

func (s *inventoryService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Inventory, int64, error) {
	query.SetDefaults()
	return s.inventoryRepo.FindAll(ctx, query)
}

func (s *inventoryService) StockIn(ctx context.Context, userID uuid.UUID, req *model.StockInRequest) error {
	productID, err := uuid.Parse(req.ProductID)
	if err != nil {
		return model.NewValidationError("invalid product ID")
	}

	// Verify inventory exists
	_, err = s.inventoryRepo.FindByProductID(ctx, productID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("inventory")
		}
		return model.NewInternalError("failed to get inventory")
	}

	// Update stock
	if err := s.inventoryRepo.UpdateStock(ctx, productID, req.Quantity); err != nil {
		s.logger.Error("failed to update stock", zap.Error(err))
		return model.NewInternalError("failed to update stock")
	}

	// Create log
	log := &model.InventoryLog{
		ProductID:      productID,
		QuantityChange: req.Quantity,
		Type:           model.InventoryLogTypeIn,
		Notes:          req.Notes,
		CreatedBy:      userID,
	}

	if err := s.inventoryRepo.CreateLog(ctx, log); err != nil {
		s.logger.Error("failed to create inventory log", zap.Error(err))
	}

	return nil
}

func (s *inventoryService) StockOut(ctx context.Context, userID uuid.UUID, req *model.StockOutRequest) error {
	productID, err := uuid.Parse(req.ProductID)
	if err != nil {
		return model.NewValidationError("invalid product ID")
	}

	// Verify inventory exists and has enough stock
	inventory, err := s.inventoryRepo.FindByProductID(ctx, productID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("inventory")
		}
		return model.NewInternalError("failed to get inventory")
	}

	if inventory.Quantity < req.Quantity {
		return model.NewValidationError("insufficient stock")
	}

	// Update stock (negative)
	if err := s.inventoryRepo.UpdateStock(ctx, productID, -req.Quantity); err != nil {
		s.logger.Error("failed to update stock", zap.Error(err))
		return model.NewInternalError("failed to update stock")
	}

	// Create log
	log := &model.InventoryLog{
		ProductID:      productID,
		QuantityChange: -req.Quantity,
		Type:           model.InventoryLogTypeOut,
		Notes:          req.Reason,
		CreatedBy:      userID,
	}

	if err := s.inventoryRepo.CreateLog(ctx, log); err != nil {
		s.logger.Error("failed to create inventory log", zap.Error(err))
	}

	return nil
}

func (s *inventoryService) StockAdjustment(ctx context.Context, userID uuid.UUID, req *model.StockAdjustmentRequest) error {
	productID, err := uuid.Parse(req.ProductID)
	if err != nil {
		return model.NewValidationError("invalid product ID")
	}

	inventory, err := s.inventoryRepo.FindByProductID(ctx, productID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("inventory")
		}
		return model.NewInternalError("failed to get inventory")
	}

	difference := req.ActualQuantity - inventory.Quantity

	if err := s.inventoryRepo.UpdateStock(ctx, productID, difference); err != nil {
		s.logger.Error("failed to adjust stock", zap.Error(err))
		return model.NewInternalError("failed to adjust stock")
	}

	// Create log
	log := &model.InventoryLog{
		ProductID:      productID,
		QuantityChange: difference,
		Type:           model.InventoryLogTypeAdjustment,
		Notes:          req.Notes,
		CreatedBy:      userID,
	}

	if err := s.inventoryRepo.CreateLog(ctx, log); err != nil {
		s.logger.Error("failed to create inventory log", zap.Error(err))
	}

	return nil
}

func (s *inventoryService) GetAlerts(ctx context.Context) ([]model.Inventory, error) {
	return s.inventoryRepo.FindBelowMinStock(ctx)
}

func (s *inventoryService) GetLogs(ctx context.Context, productID uuid.UUID, query *model.PaginationQuery) ([]model.InventoryLog, int64, error) {
	query.SetDefaults()
	return s.inventoryRepo.GetStockHistory(ctx, productID, query)
}
