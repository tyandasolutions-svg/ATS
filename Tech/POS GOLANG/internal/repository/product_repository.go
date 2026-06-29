package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

type productRepository struct {
	db *gorm.DB
}

func NewProductRepository(db *gorm.DB) ProductRepository {
	return &productRepository{db: db}
}

func (r *productRepository) Create(ctx context.Context, product *model.Product) error {
	return r.db.WithContext(ctx).Create(product).Error
}

func (r *productRepository) FindByID(ctx context.Context, id uuid.UUID) (*model.Product, error) {
	var product model.Product
	err := r.db.WithContext(ctx).Preload("Category").Preload("Inventory").
		Where("id = ?", id).First(&product).Error
	if err != nil {
		return nil, err
	}
	return &product, nil
}

func (r *productRepository) FindBySKU(ctx context.Context, sku string) (*model.Product, error) {
	var product model.Product
	err := r.db.WithContext(ctx).Where("sku = ?", sku).First(&product).Error
	if err != nil {
		return nil, err
	}
	return &product, nil
}

func (r *productRepository) FindByCategory(ctx context.Context, categoryID uuid.UUID, query *model.PaginationQuery) ([]model.Product, int64, error) {
	var products []model.Product
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Product{}).Where("category_id = ?", categoryID)

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Category").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Order(query.Sort + " " + query.Order).
		Find(&products).Error

	return products, total, err
}

func (r *productRepository) FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Product, int64, error) {
	var products []model.Product
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Product{})

	if query.Search != "" {
		db = db.Where("name ILIKE ? OR sku ILIKE ?", "%"+query.Search+"%", "%"+query.Search+"%")
	}

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Category").Preload("Inventory").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Order(query.Sort + " " + query.Order).
		Find(&products).Error

	return products, total, err
}

func (r *productRepository) SearchByName(ctx context.Context, name string, query *model.PaginationQuery) ([]model.Product, int64, error) {
	var products []model.Product
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Product{}).
		Where("name ILIKE ? AND is_active = true", "%"+name+"%")

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Category").Preload("Inventory").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Find(&products).Error

	return products, total, err
}

func (r *productRepository) FindLowStock(ctx context.Context) ([]model.Product, error) {
	var products []model.Product
	err := r.db.WithContext(ctx).
		Joins("JOIN inventories ON inventories.product_id = products.id").
		Where("inventories.quantity <= inventories.min_stock").
		Preload("Inventory").
		Find(&products).Error
	return products, err
}

func (r *productRepository) Update(ctx context.Context, product *model.Product) error {
	return r.db.WithContext(ctx).Save(product).Error
}

func (r *productRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", id).Delete(&model.Product{}).Error
}
