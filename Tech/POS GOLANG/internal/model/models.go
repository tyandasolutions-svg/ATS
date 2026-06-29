package model

import "github.com/google/uuid"

type User struct {
	BaseModel
	Name         string `gorm:"type:varchar(100);not null" json:"name" binding:"required"`
	Email        string `gorm:"type:varchar(100);uniqueIndex;not null" json:"email" binding:"required,email"`
	PasswordHash string `gorm:"type:varchar(255);not null" json:"-"`
	Role         Role   `gorm:"type:varchar(20);not null;default:'cashier'" json:"role"`
	Phone        string `gorm:"type:varchar(20)" json:"phone"`
	IsActive     bool   `gorm:"default:true" json:"is_active"`
}

type Category struct {
	BaseModel
	Name        string    `gorm:"type:varchar(100);not null" json:"name" binding:"required"`
	Slug        string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"slug"`
	Description string    `gorm:"type:text" json:"description"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	Products    []Product `gorm:"foreignKey:CategoryID" json:"products,omitempty"`
}

type Product struct {
	BaseModel
	CategoryID  uuid.UUID `gorm:"type:uuid;index" json:"category_id" binding:"required"`
	SKU         string    `gorm:"type:varchar(50);uniqueIndex;not null" json:"sku" binding:"required"`
	Name        string    `gorm:"type:varchar(200);not null;index" json:"name" binding:"required"`
	Description string    `gorm:"type:text" json:"description"`
	Price       float64   `gorm:"type:decimal(15,2);not null" json:"price" binding:"required,gt=0"`
	CostPrice   float64   `gorm:"type:decimal(15,2);not null" json:"cost_price" binding:"required,gte=0"`
	ImageURL    string    `gorm:"type:varchar(500)" json:"image_url"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	Category    Category  `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Inventory   Inventory `gorm:"foreignKey:ProductID" json:"inventory,omitempty"`
}

type Inventory struct {
	BaseModel
	ProductID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"product_id"`
	Quantity  int       `gorm:"not null;default:0" json:"quantity"`
	MinStock  int       `gorm:"not null;default:10" json:"min_stock"`
	MaxStock  int       `gorm:"not null;default:1000" json:"max_stock"`
	Location  string    `gorm:"type:varchar(100)" json:"location"`
	Product   Product   `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type InventoryLog struct {
	BaseModel
	ProductID      uuid.UUID        `gorm:"type:uuid;index;not null" json:"product_id"`
	QuantityChange int              `gorm:"not null" json:"quantity_change"`
	Type           InventoryLogType `gorm:"type:varchar(20);not null" json:"type"`
	ReferenceID    string           `gorm:"type:varchar(100)" json:"reference_id"`
	Notes          string           `gorm:"type:text" json:"notes"`
	CreatedBy      uuid.UUID        `gorm:"type:uuid" json:"created_by"`
	Product        Product          `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type Order struct {
	BaseModel
	OrderNumber    string        `gorm:"type:varchar(50);uniqueIndex;not null" json:"order_number"`
	UserID         uuid.UUID     `gorm:"type:uuid;index;not null" json:"user_id"`
	CustomerName   string        `gorm:"type:varchar(100)" json:"customer_name"`
	Subtotal       float64       `gorm:"type:decimal(15,2);not null" json:"subtotal"`
	TaxAmount      float64       `gorm:"type:decimal(15,2);not null;default:0" json:"tax_amount"`
	DiscountAmount float64       `gorm:"type:decimal(15,2);not null;default:0" json:"discount_amount"`
	TotalAmount    float64       `gorm:"type:decimal(15,2);not null" json:"total_amount"`
	Status         OrderStatus   `gorm:"type:varchar(20);not null;default:'pending';index" json:"status"`
	PaymentMethod  PaymentMethod `gorm:"type:varchar(20)" json:"payment_method"`
	PaymentStatus  PaymentStatus `gorm:"type:varchar(20);default:'pending'" json:"payment_status"`
	Notes          string        `gorm:"type:text" json:"notes"`
	Items          []OrderItem   `gorm:"foreignKey:OrderID" json:"items,omitempty"`
	User           User          `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Payments       []Payment     `gorm:"foreignKey:OrderID" json:"payments,omitempty"`
}

type OrderItem struct {
	BaseModel
	OrderID     uuid.UUID `gorm:"type:uuid;index;not null" json:"order_id"`
	ProductID   uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	ProductName string    `gorm:"type:varchar(200);not null" json:"product_name"`
	Quantity    int       `gorm:"not null" json:"quantity" binding:"required,gt=0"`
	UnitPrice   float64   `gorm:"type:decimal(15,2);not null" json:"unit_price"`
	Discount    float64   `gorm:"type:decimal(15,2);default:0" json:"discount"`
	Subtotal    float64   `gorm:"type:decimal(15,2);not null" json:"subtotal"`
	Product     Product   `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type Payment struct {
	BaseModel
	OrderID          uuid.UUID     `gorm:"type:uuid;index;not null" json:"order_id"`
	PaymentMethod    PaymentMethod `gorm:"type:varchar(20);not null" json:"payment_method"`
	Amount           float64       `gorm:"type:decimal(15,2);not null" json:"amount"`
	ReferenceNumber  string        `gorm:"type:varchar(100)" json:"reference_number"`
	Status           PaymentStatus `gorm:"type:varchar(20);not null;default:'pending'" json:"status"`
	ProviderResponse string        `gorm:"type:text" json:"provider_response,omitempty"`
	PaidAt           *string       `gorm:"type:timestamp" json:"paid_at,omitempty"`
	Order            Order         `gorm:"foreignKey:OrderID" json:"order,omitempty"`
}

type Customer struct {
	BaseModel
	Name       string  `gorm:"type:varchar(100);not null" json:"name" binding:"required"`
	Email      string  `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	Phone      string  `gorm:"type:varchar(20);index" json:"phone"`
	Points     int     `gorm:"default:0" json:"points"`
	TotalSpent float64 `gorm:"type:decimal(15,2);default:0" json:"total_spent"`
}
