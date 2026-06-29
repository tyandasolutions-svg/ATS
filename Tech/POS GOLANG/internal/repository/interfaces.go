package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
)

type UserRepository interface {
	Create(ctx context.Context, user *model.User) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.User, error)
	FindByEmail(ctx context.Context, email string) (*model.User, error)
	FindByRole(ctx context.Context, role model.Role) ([]model.User, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.User, int64, error)
	Update(ctx context.Context, user *model.User) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type CategoryRepository interface {
	Create(ctx context.Context, category *model.Category) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.Category, error)
	FindBySlug(ctx context.Context, slug string) (*model.Category, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Category, int64, error)
	Update(ctx context.Context, category *model.Category) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ProductRepository interface {
	Create(ctx context.Context, product *model.Product) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.Product, error)
	FindBySKU(ctx context.Context, sku string) (*model.Product, error)
	FindByCategory(ctx context.Context, categoryID uuid.UUID, query *model.PaginationQuery) ([]model.Product, int64, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Product, int64, error)
	SearchByName(ctx context.Context, name string, query *model.PaginationQuery) ([]model.Product, int64, error)
	FindLowStock(ctx context.Context) ([]model.Product, error)
	Update(ctx context.Context, product *model.Product) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type InventoryRepository interface {
	Create(ctx context.Context, inventory *model.Inventory) error
	FindByProductID(ctx context.Context, productID uuid.UUID) (*model.Inventory, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Inventory, int64, error)
	FindBelowMinStock(ctx context.Context) ([]model.Inventory, error)
	UpdateStock(ctx context.Context, productID uuid.UUID, quantity int) error
	GetStockHistory(ctx context.Context, productID uuid.UUID, query *model.PaginationQuery) ([]model.InventoryLog, int64, error)
	CreateLog(ctx context.Context, log *model.InventoryLog) error
}

type OrderRepository interface {
	Create(ctx context.Context, order *model.Order) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.Order, error)
	FindByOrderNumber(ctx context.Context, orderNumber string) (*model.Order, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Order, int64, error)
	FindByStatus(ctx context.Context, status model.OrderStatus, query *model.PaginationQuery) ([]model.Order, int64, error)
	FindByDateRange(ctx context.Context, startDate, endDate string) ([]model.Order, error)
	GetDailySummary(ctx context.Context, date string) (*DailySummary, error)
	Update(ctx context.Context, order *model.Order) error
}

type PaymentRepository interface {
	Create(ctx context.Context, payment *model.Payment) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.Payment, error)
	FindByOrderID(ctx context.Context, orderID uuid.UUID) ([]model.Payment, error)
	FindByDateRange(ctx context.Context, startDate, endDate string) ([]model.Payment, error)
	Update(ctx context.Context, payment *model.Payment) error
}

type CustomerRepository interface {
	Create(ctx context.Context, customer *model.Customer) error
	FindByID(ctx context.Context, id uuid.UUID) (*model.Customer, error)
	FindByEmail(ctx context.Context, email string) (*model.Customer, error)
	FindAll(ctx context.Context, query *model.PaginationQuery) ([]model.Customer, int64, error)
	Update(ctx context.Context, customer *model.Customer) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// Report structs
type DailySummary struct {
	Date           string  `json:"date"`
	TotalOrders    int64   `json:"total_orders"`
	TotalRevenue   float64 `json:"total_revenue"`
	TotalItems     int64   `json:"total_items"`
	AverageOrder   float64 `json:"average_order"`
}
