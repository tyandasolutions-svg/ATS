package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"gorm.io/gorm"
)

type orderRepository struct {
	db *gorm.DB
}

func NewOrderRepository(db *gorm.DB) OrderRepository {
	return &orderRepository{db: db}
}

func (r *orderRepository) Create(ctx context.Context, order *model.Order) error {
	return r.db.WithContext(ctx).Create(order).Error
}

func (r *orderRepository) FindByID(ctx context.Context, id uuid.UUID) (*model.Order, error) {
	var order model.Order
	err := r.db.WithContext(ctx).
		Preload("Items").
		Preload("Items.Product").
		Preload("User").
		Preload("Payments").
		Where("id = ?", id).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByOrderNumber(ctx context.Context, orderNumber string) (*model.Order, error) {
	var order model.Order
	err := r.db.WithContext(ctx).
		Preload("Items").
		Preload("Payments").
		Where("order_number = ?", orderNumber).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Order, int64, error) {
	var orders []model.Order
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Order{})

	if query.Search != "" {
		db = db.Where("order_number ILIKE ? OR customer_name ILIKE ?",
			"%"+query.Search+"%", "%"+query.Search+"%")
	}

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Items").Preload("User").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Order(query.Sort + " " + query.Order).
		Find(&orders).Error

	return orders, total, err
}

func (r *orderRepository) FindByStatus(ctx context.Context, status model.OrderStatus, query *model.PaginationQuery) ([]model.Order, int64, error) {
	var orders []model.Order
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Order{}).Where("status = ?", status)

	err := db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = db.Preload("Items").
		Offset(query.GetOffset()).Limit(query.PerPage).
		Order("created_at desc").
		Find(&orders).Error

	return orders, total, err
}

func (r *orderRepository) FindByDateRange(ctx context.Context, startDate, endDate string) ([]model.Order, error) {
	var orders []model.Order
	err := r.db.WithContext(ctx).
		Where("created_at BETWEEN ? AND ?", startDate, endDate).
		Preload("Items").
		Find(&orders).Error
	return orders, err
}

func (r *orderRepository) GetDailySummary(ctx context.Context, date string) (*DailySummary, error) {
	var summary DailySummary
	summary.Date = date

	err := r.db.WithContext(ctx).Model(&model.Order{}).
		Where("DATE(created_at) = ? AND status = ?", date, model.OrderStatusCompleted).
		Select("COUNT(*) as total_orders, COALESCE(SUM(total_amount), 0) as total_revenue").
		Scan(&summary).Error
	if err != nil {
		return nil, err
	}

	if summary.TotalOrders > 0 {
		summary.AverageOrder = summary.TotalRevenue / float64(summary.TotalOrders)
	}

	r.db.WithContext(ctx).Model(&model.OrderItem{}).
		Joins("JOIN orders ON orders.id = order_items.order_id").
		Where("DATE(orders.created_at) = ? AND orders.status = ?", date, model.OrderStatusCompleted).
		Select("COALESCE(SUM(order_items.quantity), 0)").
		Scan(&summary.TotalItems)

	return &summary, nil
}

func (r *orderRepository) Update(ctx context.Context, order *model.Order) error {
	return r.db.WithContext(ctx).Save(order).Error
}
