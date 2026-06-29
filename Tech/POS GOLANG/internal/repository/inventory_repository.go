package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

type inventoryRepository struct {
	db *gorm.DB
}

func NewInventoryRepository(db *gorm.DB) InventoryRepository {
	return &inventoryRepository{db: db}
}

func (r *inventoryRepository) Create(ctx context.Context, inventory *model.Inventory) error {
	return r.db.WithContext(ctx).Create(inventory).Error
}

func (r *inventoryRepository) FindByProductID(ctx context.Context, productID uuid.UUID) (*model.Inventory, error) {
	var inventory model.Inventory
	err := r.db.WithContext(ctx).Preload("Product").
		Where("product_id = ?", productID).First(&inventory).Error
	if err != nil {
		return nil, err
	}
	return &inventory, nil
}

func (r *inventoryRepository) FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Inventory, int64, error) {
	var inventories []model.Inventory
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Inventory{})

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Product").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Find(&inventories).Error

	return inventories, total, err
}

func (r *inventoryRepository) FindBelowMinStock(ctx context.Context) ([]model.Inventory, error) {
	var inventories []model.Inventory
	err := r.db.WithContext(ctx).
		Where("quantity <= min_stock").
		Preload("Product").
		Find(&inventories).Error
	return inventories, err
}

func (r *inventoryRepository) UpdateStock(ctx context.Context, productID uuid.UUID, quantity int) error {
	return r.db.WithContext(ctx).
		Model(&model.Inventory{}).
		Where("product_id = ?", productID).
		Update("quantity", gorm.Expr("quantity + ?", quantity)).Error
}

func (r *inventoryRepository) GetStockHistory(ctx context.Context, productID uuid.UUID, query *model.PaginationQuery) ([]model.InventoryLog, int64, error) {
	var logs []model.InventoryLog
	var total int64

	db := r.db.WithContext(ctx).Model(&model.InventoryLog{}).Where("product_id = ?", productID)

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Offset(query.GetOffset()).Limit(query.PerPage).
		Order("created_at desc").
		Find(&logs).Error

	return logs, total, err
}

func (r *inventoryRepository) CreateLog(ctx context.Context, log *model.InventoryLog) error {
	return r.db.WithContext(ctx).Create(log).Error
}
