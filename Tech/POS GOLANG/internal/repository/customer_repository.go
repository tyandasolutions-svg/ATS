package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

type customerRepository struct {
	db *gorm.DB
}

func NewCustomerRepository(db *gorm.DB) CustomerRepository {
	return &customerRepository{db: db}
}

func (r *customerRepository) Create(ctx context.Context, customer *model.Customer) error {
	return r.db.WithContext(ctx).Create(customer).Error
}

func (r *customerRepository) FindByID(ctx context.Context, id uuid.UUID) (*model.Customer, error) {
	var customer model.Customer
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&customer).Error
	if err != nil {
		return nil, err
	}
	return &customer, nil
}

func (r *customerRepository) FindByEmail(ctx context.Context, email string) (*model.Customer, error) {
	var customer model.Customer
	err := r.db.WithContext(ctx).Where("email = ?", email).First(&customer).Error
	if err != nil {
		return nil, err
	}
	return &customer, nil
}

func (r *customerRepository) FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Customer, int64, error) {
	var customers []model.Customer
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Customer{})

	if query.Search != "" {
		db = db.Where("name ILIKE ? OR email ILIKE ? OR phone ILIKE ?",
			"%"+query.Search+"%", "%"+query.Search+"%", "%"+query.Search+"%")
	}

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Offset(query.GetOffset()).Limit(query.PerPage).
		Order(query.Sort + " " + query.Order).
		Find(&customers).Error

	return customers, total, err
}

func (r *customerRepository) Update(ctx context.Context, customer *model.Customer) error {
	return r.db.WithContext(ctx).Save(customer).Error
}

func (r *customerRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", id).Delete(&model.Customer{}).Error
}
