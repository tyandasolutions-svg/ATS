package tests

import (
	"context"
	"testing"

	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"github.com/kosasen/pos-golang/internal/service"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("failed to open test database: %v", err)
	}

	err = db.AutoMigrate(
		&model.User{},
		&model.Category{},
		&model.Product{},
		&model.Inventory{},
		&model.InventoryLog{},
		&model.Order{},
		&model.OrderItem{},
		&model.Payment{},
		&model.Customer{},
	)
	if err != nil {
		t.Fatalf("failed to migrate test database: %v", err)
	}

	return db
}

func TestUserService_GetByID(t *testing.T) {
	db := setupTestDB(t)
	logger := zap.NewNop()

	userRepo := repository.NewUserRepository(db)
	userSvc := service.NewUserService(userRepo, logger)

	// Create a test user
	hash, _ := bcrypt.GenerateFromPassword([]byte("password"), bcrypt.DefaultCost)
	user := &model.User{
		Name:         "Test User",
		Email:        "test@example.com",
		PasswordHash: string(hash),
		Role:         model.RoleCashier,
		IsActive:     true,
	}
	db.Create(user)

	// Test GetByID
	ctx := context.Background()
	result, err := userSvc.GetByID(ctx, user.ID)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	if result.Email != "test@example.com" {
		t.Errorf("expected email test@example.com, got: %s", result.Email)
	}
}

func TestCategoryService_Create(t *testing.T) {
	db := setupTestDB(t)
	logger := zap.NewNop()

	categoryRepo := repository.NewCategoryRepository(db)
	categorySvc := service.NewCategoryService(categoryRepo, logger)

	ctx := context.Background()

	req := &model.CreateCategoryRequest{
		Name:        "Electronics",
		Description: "Electronic products",
	}

	category, err := categorySvc.Create(ctx, req)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	if category.Name != "Electronics" {
		t.Errorf("expected name Electronics, got: %s", category.Name)
	}

	if category.Slug != "electronics" {
		t.Errorf("expected slug electronics, got: %s", category.Slug)
	}

	// Test duplicate
	_, err = categorySvc.Create(ctx, req)
	if err == nil {
		t.Error("expected conflict error for duplicate category")
	}
}

func TestInventoryService_StockIn(t *testing.T) {
	db := setupTestDB(t)
	logger := zap.NewNop()

	inventoryRepo := repository.NewInventoryRepository(db)
	inventorySvc := service.NewInventoryService(inventoryRepo, logger)

	// Create test product and inventory
	product := &model.Product{
		SKU:       "TEST-001",
		Name:      "Test Product",
		Price:     10000,
		CostPrice: 8000,
		IsActive:  true,
	}
	db.Create(product)

	inventory := &model.Inventory{
		ProductID: product.ID,
		Quantity:  0,
		MinStock:  10,
		MaxStock:  100,
	}
	db.Create(inventory)

	ctx := context.Background()

	// Test stock in
	req := &model.StockInRequest{
		ProductID: product.ID.String(),
		Quantity:  50,
		Notes:     "Initial stock",
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte("password"), bcrypt.DefaultCost)
	user := &model.User{
		Name:         "Admin",
		Email:        "admin@test.com",
		PasswordHash: string(hash),
		Role:         model.RoleAdmin,
		IsActive:     true,
	}
	db.Create(user)

	err := inventorySvc.StockIn(ctx, user.ID, req)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Verify stock updated
	updated, _ := inventorySvc.GetByProductID(ctx, product.ID)
	if updated.Quantity != 50 {
		t.Errorf("expected quantity 50, got: %d", updated.Quantity)
	}
}
