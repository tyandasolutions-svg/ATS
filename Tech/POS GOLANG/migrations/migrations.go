package migrations

import (
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(
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
}

func Seed(db *gorm.DB) error {
	// Seed admin user
	admin := &model.User{
		Name:         "Admin",
		Email:        "admin@pos.com",
		PasswordHash: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy", // password123
		Role:         model.RoleAdmin,
		IsActive:     true,
	}

	result := db.Where("email = ?", admin.Email).FirstOrCreate(admin)
	if result.Error != nil {
		return result.Error
	}

	// Seed categories
	categories := []model.Category{
		{Name: "Makanan", Slug: "makanan", Description: "Produk makanan", IsActive: true},
		{Name: "Minuman", Slug: "minuman", Description: "Produk minuman", IsActive: true},
		{Name: "Snack", Slug: "snack", Description: "Produk snack", IsActive: true},
		{Name: "Peralatan", Slug: "peralatan", Description: "Peralatan rumah tangga", IsActive: true},
	}

	for _, cat := range categories {
		db.Where("slug = ?", cat.Slug).FirstOrCreate(&cat)
	}

	return nil
}
