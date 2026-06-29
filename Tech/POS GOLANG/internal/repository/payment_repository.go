package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) Create(ctx context.Context, payment *model.Payment) error {
	return r.db.WithContext(ctx).Create(payment).Error
}

func (r *paymentRepository) FindByID(ctx context.Context, id uuid.UUID) (*model.Payment, error) {
	var payment model.Payment
	err := r.db.WithContext(ctx).Preload("Order").Where("id = ?", id).First(&payment).Error
	if err != nil {
		return nil, err
	}
	return &payment, nil
}

func (r *paymentRepository) FindByOrderID(ctx context.Context, orderID uuid.UUID) ([]model.Payment, error) {
	var payments []model.Payment
	err := r.db.WithContext(ctx).Where("order_id = ?", orderID).Find(&payments).Error
	return payments, err
}

func (r *paymentRepository) FindByDateRange(ctx context.Context, startDate, endDate string) ([]model.Payment, error) {
	var payments []model.Payment
	err := r.db.WithContext(ctx).
		Where("created_at BETWEEN ? AND ? AND status = ?", startDate, endDate, model.PaymentStatusSuccess).
		Find(&payments).Error
	return payments, err
}

func (r *paymentRepository) Update(ctx context.Context, payment *model.Payment) error {
	return r.db.WithContext(ctx).Save(payment).Error
}
