package model

// DTOs for Request/Response

// Auth DTOs
type RegisterRequest struct {
	Name     string `json:"name" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
	Phone    string `json:"phone"`
	Role     Role   `json:"role"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

// Product DTOs
type CreateProductRequest struct {
	CategoryID  string  `json:"category_id" binding:"required"`
	SKU         string  `json:"sku" binding:"required"`
	Name        string  `json:"name" binding:"required"`
	Description string  `json:"description"`
	Price       float64 `json:"price" binding:"required,gt=0"`
	CostPrice   float64 `json:"cost_price" binding:"required,gte=0"`
	ImageURL    string  `json:"image_url"`
	MinStock    int     `json:"min_stock"`
	MaxStock    int     `json:"max_stock"`
}

type UpdateProductRequest struct {
	CategoryID  string  `json:"category_id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price" binding:"gte=0"`
	CostPrice   float64 `json:"cost_price" binding:"gte=0"`
	ImageURL    string  `json:"image_url"`
	IsActive    *bool   `json:"is_active"`
}

// Category DTOs
type CreateCategoryRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

type UpdateCategoryRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	IsActive    *bool  `json:"is_active"`
}

// Order DTOs
type CreateOrderRequest struct {
	CustomerName string             `json:"customer_name"`
	Items        []OrderItemRequest `json:"items" binding:"required,min=1"`
	Discount     float64            `json:"discount"`
	Notes        string             `json:"notes"`
	PaymentMethod PaymentMethod     `json:"payment_method" binding:"required"`
}

type OrderItemRequest struct {
	ProductID string  `json:"product_id" binding:"required"`
	Quantity  int     `json:"quantity" binding:"required,gt=0"`
	Discount  float64 `json:"discount"`
}

// Inventory DTOs
type StockInRequest struct {
	ProductID string `json:"product_id" binding:"required"`
	Quantity  int    `json:"quantity" binding:"required,gt=0"`
	Notes     string `json:"notes"`
}

type StockOutRequest struct {
	ProductID string `json:"product_id" binding:"required"`
	Quantity  int    `json:"quantity" binding:"required,gt=0"`
	Reason    string `json:"reason" binding:"required"`
}

type StockAdjustmentRequest struct {
	ProductID      string `json:"product_id" binding:"required"`
	ActualQuantity int    `json:"actual_quantity" binding:"required,gte=0"`
	Notes          string `json:"notes"`
}

// Payment DTOs
type ProcessPaymentRequest struct {
	OrderID       string        `json:"order_id" binding:"required"`
	PaymentMethod PaymentMethod `json:"payment_method" binding:"required"`
	Amount        float64       `json:"amount" binding:"required,gt=0"`
}

type PaymentCallbackRequest struct {
	OrderID         string `json:"order_id"`
	TransactionID   string `json:"transaction_id"`
	Status          string `json:"status"`
	PaymentType     string `json:"payment_type"`
	GrossAmount     string `json:"gross_amount"`
	SignatureKey     string `json:"signature_key"`
}

// Customer DTOs
type CreateCustomerRequest struct {
	Name  string `json:"name" binding:"required"`
	Email string `json:"email" binding:"email"`
	Phone string `json:"phone"`
}

type UpdateCustomerRequest struct {
	Name  string `json:"name"`
	Email string `json:"email" binding:"omitempty,email"`
	Phone string `json:"phone"`
}

// Query Parameters
type PaginationQuery struct {
	Page    int    `form:"page" binding:"min=1"`
	PerPage int    `form:"per_page" binding:"min=1,max=100"`
	Sort    string `form:"sort"`
	Order   string `form:"order" binding:"omitempty,oneof=asc desc"`
	Search  string `form:"search"`
}

func (p *PaginationQuery) SetDefaults() {
	if p.Page == 0 {
		p.Page = 1
	}
	if p.PerPage == 0 {
		p.PerPage = 20
	}
	if p.Order == "" {
		p.Order = "desc"
	}
	if p.Sort == "" {
		p.Sort = "created_at"
	}
}

func (p *PaginationQuery) GetOffset() int {
	return (p.Page - 1) * p.PerPage
}
