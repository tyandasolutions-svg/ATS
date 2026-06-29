package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BaseModel struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Enum Types

type Role string

const (
	RoleAdmin   Role = "admin"
	RoleManager Role = "manager"
	RoleCashier Role = "cashier"
)

type OrderStatus string

const (
	OrderStatusPending   OrderStatus = "pending"
	OrderStatusCompleted OrderStatus = "completed"
	OrderStatusCancelled OrderStatus = "cancelled"
	OrderStatusRefunded  OrderStatus = "refunded"
)

type PaymentMethod string

const (
	PaymentMethodCash    PaymentMethod = "cash"
	PaymentMethodCard    PaymentMethod = "card"
	PaymentMethodEwallet PaymentMethod = "ewallet"
	PaymentMethodQRIS    PaymentMethod = "qris"
)

type PaymentStatus string

const (
	PaymentStatusPending  PaymentStatus = "pending"
	PaymentStatusSuccess  PaymentStatus = "success"
	PaymentStatusFailed   PaymentStatus = "failed"
	PaymentStatusRefunded PaymentStatus = "refunded"
)

type InventoryLogType string

const (
	InventoryLogTypeIn         InventoryLogType = "in"
	InventoryLogTypeOut        InventoryLogType = "out"
	InventoryLogTypeAdjustment InventoryLogType = "adjustment"
)
