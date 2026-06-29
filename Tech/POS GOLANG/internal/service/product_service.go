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

type ProductService interface {
	Create(ctx context.Context, req *model.CreateProductRequest) (*model.Product, error)
	GetByID(ctx context.Context, id uuid.UUID) (*model.Product, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Product, int64, error)
	Search(ctx context.Context, keyword string, query *model.PaginationQuery) ([]model.Product, int64, error)
	Update(ctx context.Context, id uuid.UUID, req *model.UpdateProductRequest) (*model.Product, error)
	Delete(ctx context.Context, id uuid.UUID) error
	GetLowStock(ctx context.Context) ([]model.Product, error)
}

type productService struct {
	productRepo   repository.ProductRepository
	inventoryRepo repository.InventoryRepository
	logger        *zap.Logger
}

func NewProductService(productRepo repository.ProductRepository, inventoryRepo repository.InventoryRepository, logger *zap.Logger) ProductService {
	return &productService{
		productRepo:   productRepo,
		inventoryRepo: inventoryRepo,
		logger:        logger,
	}
}

func (s *productService) Create(ctx context.Context, req *model.CreateProductRequest) (*model.Product, error) {
	// Check SKU uniqueness
	existing, _ := s.productRepo.FindBySKU(ctx, req.SKU)
	if existing != nil {
		return nil, model.NewConflictError("product with this SKU already exists")
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return nil, model.NewValidationError("invalid category ID")
	}

	product := &model.Product{
		CategoryID:  categoryID,
		SKU:         req.SKU,
		Name:        req.Name,
		Description: req.Description,
		Price:       req.Price,
		CostPrice:   req.CostPrice,
		ImageURL:    req.ImageURL,
		IsActive:    true,
	}

	if err := s.productRepo.Create(ctx, product); err != nil {
		s.logger.Error("failed to create product", zap.Error(err))
		return nil, model.NewInternalError("failed to create product")
	}

	// Create inventory record
	minStock := 10
	maxStock := 1000
	if req.MinStock > 0 {
		minStock = req.MinStock
	}
	if req.MaxStock > 0 {
		maxStock = req.MaxStock
	}

	inventory := &model.Inventory{
		ProductID: product.ID,
		Quantity:  0,
		MinStock:  minStock,
		MaxStock:  maxStock,
	}

	if err := s.inventoryRepo.Create(ctx, inventory); err != nil {
		s.logger.Error("failed to create inventory", zap.Error(err))
		return nil, model.NewInternalError("failed to create inventory record")
	}

	return product, nil
}

func (s *productService) GetByID(ctx context.Context, id uuid.UUID) (*model.Product, error) {
	product, err := s.productRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("product")
		}
		return nil, model.NewInternalError("failed to get product")
	}
	return product, nil
}

func (s *productService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Product, int64, error) {
	query.SetDefaults()
	return s.productRepo.FindAll(ctx, query)
}

func (s *productService) Search(ctx context.Context, keyword string, query *model.PaginationQuery) ([]model.Product, int64, error) {
	query.SetDefaults()
	return s.productRepo.SearchByName(ctx, keyword, query)
}

func (s *productService) Update(ctx context.Context, id uuid.UUID, req *model.UpdateProductRequest) (*model.Product, error) {
	product, err := s.productRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("product")
		}
		return nil, model.NewInternalError("failed to get product")
	}

	if req.CategoryID != "" {
		catID, err := uuid.Parse(req.CategoryID)
		if err != nil {
			return nil, model.NewValidationError("invalid category ID")
		}
		product.CategoryID = catID
	}
	if req.Name != "" {
		product.Name = req.Name
	}
	if req.Description != "" {
		product.Description = req.Description
	}
	if req.Price > 0 {
		product.Price = req.Price
	}
	if req.CostPrice > 0 {
		product.CostPrice = req.CostPrice
	}
	if req.ImageURL != "" {
		product.ImageURL = req.ImageURL
	}
	if req.IsActive != nil {
		product.IsActive = *req.IsActive
	}

	if err := s.productRepo.Update(ctx, product); err != nil {
		return nil, model.NewInternalError("failed to update product")
	}
	return product, nil
}

func (s *productService) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := s.productRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("product")
		}
		return model.NewInternalError("failed to get product")
	}
	return s.productRepo.Delete(ctx, id)
}

func (s *productService) GetLowStock(ctx context.Context) ([]model.Product, error) {
	return s.productRepo.FindLowStock(ctx)
}
