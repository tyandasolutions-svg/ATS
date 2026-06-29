package service

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type CategoryService interface {
	Create(ctx context.Context, req *model.CreateCategoryRequest) (*model.Category, error)
	GetByID(ctx context.Context, id uuid.UUID) (*model.Category, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Category, int64, error)
	Update(ctx context.Context, id uuid.UUID, req *model.UpdateCategoryRequest) (*model.Category, error)
	Delete(ctx context.Context, id uuid.UUID) error
}

type categoryService struct {
	categoryRepo repository.CategoryRepository
	logger       *zap.Logger
}

func NewCategoryService(categoryRepo repository.CategoryRepository, logger *zap.Logger) CategoryService {
	return &categoryService{
		categoryRepo: categoryRepo,
		logger:       logger,
	}
}

func (s *categoryService) Create(ctx context.Context, req *model.CreateCategoryRequest) (*model.Category, error) {
	slug := generateSlug(req.Name)

	// Check if slug already exists
	existing, _ := s.categoryRepo.FindBySlug(ctx, slug)
	if existing != nil {
		return nil, model.NewConflictError("category with this name already exists")
	}

	category := &model.Category{
		Name:        req.Name,
		Slug:        slug,
		Description: req.Description,
		IsActive:    true,
	}

	if err := s.categoryRepo.Create(ctx, category); err != nil {
		s.logger.Error("failed to create category", zap.Error(err))
		return nil, model.NewInternalError("failed to create category")
	}

	return category, nil
}

func (s *categoryService) GetByID(ctx context.Context, id uuid.UUID) (*model.Category, error) {
	category, err := s.categoryRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("category")
		}
		return nil, model.NewInternalError("failed to get category")
	}
	return category, nil
}

func (s *categoryService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.Category, int64, error) {
	query.SetDefaults()
	return s.categoryRepo.FindAll(ctx, query)
}

func (s *categoryService) Update(ctx context.Context, id uuid.UUID, req *model.UpdateCategoryRequest) (*model.Category, error) {
	category, err := s.categoryRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("category")
		}
		return nil, model.NewInternalError("failed to get category")
	}

	if req.Name != "" {
		category.Name = req.Name
		category.Slug = generateSlug(req.Name)
	}
	if req.Description != "" {
		category.Description = req.Description
	}
	if req.IsActive != nil {
		category.IsActive = *req.IsActive
	}

	if err := s.categoryRepo.Update(ctx, category); err != nil {
		return nil, model.NewInternalError("failed to update category")
	}
	return category, nil
}

func (s *categoryService) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := s.categoryRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("category")
		}
		return model.NewInternalError("failed to get category")
	}
	return s.categoryRepo.Delete(ctx, id)
}

func generateSlug(name string) string {
	slug := strings.ToLower(name)
	slug = strings.ReplaceAll(slug, " ", "-")
	slug = strings.ReplaceAll(slug, "/", "-")
	return slug
}
