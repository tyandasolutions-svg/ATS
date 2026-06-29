package service

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/config"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthService interface {
	Register(ctx context.Context, req *model.RegisterRequest) (*model.User, error)
	Login(ctx context.Context, req *model.LoginRequest) (*model.LoginResponse, error)
	RefreshToken(ctx context.Context, refreshToken string) (*model.LoginResponse, error)
	ChangePassword(ctx context.Context, userID uuid.UUID, req *model.ChangePasswordRequest) error
}

type authService struct {
	userRepo repository.UserRepository
	cfg      *config.JWTConfig
	logger   *zap.Logger
}

func NewAuthService(userRepo repository.UserRepository, cfg *config.JWTConfig, logger *zap.Logger) AuthService {
	return &authService{
		userRepo: userRepo,
		cfg:      cfg,
		logger:   logger,
	}
}

func (s *authService) Register(ctx context.Context, req *model.RegisterRequest) (*model.User, error) {
	// Check if email already exists
	existing, _ := s.userRepo.FindByEmail(ctx, strings.ToLower(req.Email))
	if existing != nil {
		return nil, model.NewConflictError("email already registered")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		s.logger.Error("failed to hash password", zap.Error(err))
		return nil, model.NewInternalError("failed to process registration")
	}

	role := model.RoleCashier
	if req.Role != "" {
		role = req.Role
	}

	user := &model.User{
		Name:         req.Name,
		Email:        strings.ToLower(req.Email),
		PasswordHash: string(hashedPassword),
		Role:         role,
		Phone:        req.Phone,
		IsActive:     true,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		s.logger.Error("failed to create user", zap.Error(err))
		return nil, model.NewInternalError("failed to create user")
	}

	return user, nil
}

func (s *authService) Login(ctx context.Context, req *model.LoginRequest) (*model.LoginResponse, error) {
	user, err := s.userRepo.FindByEmail(ctx, strings.ToLower(req.Email))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, model.NewUnauthorizedError("invalid email or password")
		}
		return nil, model.NewInternalError("failed to process login")
	}

	if !user.IsActive {
		return nil, model.NewUnauthorizedError("account is deactivated")
	}

	// Compare password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, model.NewUnauthorizedError("invalid email or password")
	}

	// Generate tokens
	accessToken, err := s.generateToken(user, s.cfg.AccessExpiry)
	if err != nil {
		return nil, model.NewInternalError("failed to generate token")
	}

	refreshToken, err := s.generateToken(user, s.cfg.RefreshExpiry)
	if err != nil {
		return nil, model.NewInternalError("failed to generate token")
	}

	return &model.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (s *authService) RefreshToken(ctx context.Context, refreshToken string) (*model.LoginResponse, error) {
	claims, err := s.validateToken(refreshToken)
	if err != nil {
		return nil, model.NewUnauthorizedError("invalid or expired refresh token")
	}

	userID, err := uuid.Parse(claims["user_id"].(string))
	if err != nil {
		return nil, model.NewUnauthorizedError("invalid token")
	}

	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, model.NewUnauthorizedError("user not found")
	}

	accessToken, err := s.generateToken(user, s.cfg.AccessExpiry)
	if err != nil {
		return nil, model.NewInternalError("failed to generate token")
	}

	newRefreshToken, err := s.generateToken(user, s.cfg.RefreshExpiry)
	if err != nil {
		return nil, model.NewInternalError("failed to generate token")
	}

	return &model.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         *user,
	}, nil
}

func (s *authService) ChangePassword(ctx context.Context, userID uuid.UUID, req *model.ChangePasswordRequest) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return model.NewNotFoundError("user")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		return model.NewValidationError("old password is incorrect")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return model.NewInternalError("failed to process password change")
	}

	user.PasswordHash = string(hashedPassword)
	return s.userRepo.Update(ctx, user)
}

func (s *authService) generateToken(user *model.User, expiry time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"user_id": user.ID.String(),
		"email":   user.Email,
		"role":    string(user.Role),
		"exp":     time.Now().Add(expiry).Unix(),
		"iat":     time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.Secret))
}

func (s *authService) validateToken(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(s.cfg.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}
