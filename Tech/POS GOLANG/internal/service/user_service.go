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

type UserService interface {
	GetByID(ctx context.Context, id uuid.UUID) (*model.User, error)
	GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.User, int64, error)
	Update(ctx context.Context, id uuid.UUID, name, phone string) (*model.User, error)
	Deactivate(ctx context.Context, id uuid.UUID) error
	AssignRole(ctx context.Context, id uuid.UUID, role model.Role) error
}

type userService struct {
	userRepo repository.UserRepository
	logger   *zap.Logger
}

func NewUserService(userRepo repository.UserRepository, logger *zap.Logger) UserService {
	return &userService{
		userRepo: userRepo,
		logger:   logger,
	}
}

func (s *userService) GetByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("user")
		}
		return nil, model.NewInternalError("failed to get user")
	}
	return user, nil
}

func (s *userService) GetAll(ctx context.Context, query *model.PaginationQuery) ([]model.User, int64, error) {
	query.SetDefaults()
	return s.userRepo.FindAll(ctx, query)
}

func (s *userService) Update(ctx context.Context, id uuid.UUID, name, phone string) (*model.User, error) {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewNotFoundError("user")
		}
		return nil, model.NewInternalError("failed to get user")
	}

	if name != "" {
		user.Name = name
	}
	if phone != "" {
		user.Phone = phone
	}

	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, model.NewInternalError("failed to update user")
	}
	return user, nil
}

func (s *userService) Deactivate(ctx context.Context, id uuid.UUID) error {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("user")
		}
		return model.NewInternalError("failed to get user")
	}

	user.IsActive = false
	return s.userRepo.Update(ctx, user)
}

func (s *userService) AssignRole(ctx context.Context, id uuid.UUID, role model.Role) error {
	user, err := s.userRepo.FindByID(ctx, id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return model.NewNotFoundError("user")
		}
		return model.NewInternalError("failed to get user")
	}

	user.Role = role
	return s.userRepo.Update(ctx, user)
}
