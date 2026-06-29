package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/kosasen/pos-golang/internal/middleware"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/pkg/response"
)

type Router struct {
	Auth      *AuthHandler
	User      *UserHandler
	Category  *CategoryHandler
	Product   *ProductHandler
	Inventory *InventoryHandler
	Order     *OrderHandler
	Payment   *PaymentHandler
	Customer  *CustomerHandler
	JWTSecret string
}

func NewRouter(r *Router) *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	engine := gin.New()
	engine.Use(gin.Recovery())
	engine.Use(middleware.CORSMiddleware())
	engine.Use(middleware.RequestIDMiddleware())
	engine.Use(middleware.LoggerMiddleware())

	// Health check
	engine.GET("/health", func(c *gin.Context) {
		response.Success(c, http.StatusOK, "service is healthy", gin.H{
			"status": "UP",
		})
	})

	engine.GET("/ready", func(c *gin.Context) {
		response.Success(c, http.StatusOK, "service is ready", gin.H{
			"status": "READY",
		})
	})

	// API v1
	v1 := engine.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/register", r.Auth.Register)
			auth.POST("/login", r.Auth.Login)
			auth.POST("/refresh-token", r.Auth.RefreshToken)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(r.JWTSecret))
		{
			// Auth (protected)
			protected.POST("/auth/change-password", r.Auth.ChangePassword)

			// Users
			users := protected.Group("/users")
			{
				users.GET("", middleware.RoleMiddleware(model.RoleAdmin), r.User.GetAll)
				users.GET("/:id", r.User.GetByID)
				users.PUT("/:id", r.User.Update)
				users.DELETE("/:id", middleware.RoleMiddleware(model.RoleAdmin), r.User.Delete)
				users.PATCH("/:id/role", middleware.RoleMiddleware(model.RoleAdmin), r.User.AssignRole)
			}

			// Categories
			categories := protected.Group("/categories")
			{
				categories.GET("", r.Category.GetAll)
				categories.GET("/:id", r.Category.GetByID)
				categories.POST("", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Category.Create)
				categories.PUT("/:id", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Category.Update)
				categories.DELETE("/:id", middleware.RoleMiddleware(model.RoleAdmin), r.Category.Delete)
			}

			// Products
			products := protected.Group("/products")
			{
				products.GET("", r.Product.GetAll)
				products.GET("/:id", r.Product.GetByID)
				products.POST("", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Product.Create)
				products.PUT("/:id", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Product.Update)
				products.DELETE("/:id", middleware.RoleMiddleware(model.RoleAdmin), r.Product.Delete)
				products.GET("/search", r.Product.Search)
				products.GET("/low-stock", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Product.GetLowStock)
			}

			// Inventory
			inventory := protected.Group("/inventory")
			{
				inventory.GET("", r.Inventory.GetAll)
				inventory.GET("/:product_id", r.Inventory.GetByProductID)
				inventory.POST("/stock-in", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Inventory.StockIn)
				inventory.POST("/stock-out", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Inventory.StockOut)
				inventory.POST("/adjustment", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Inventory.StockAdjustment)
				inventory.GET("/alerts", r.Inventory.GetAlerts)
				inventory.GET("/logs", r.Inventory.GetLogs)
			}

			// Orders
			orders := protected.Group("/orders")
			{
				orders.GET("", r.Order.GetAll)
				orders.GET("/:id", r.Order.GetByID)
				orders.POST("", r.Order.Create)
				orders.PATCH("/:id/cancel", r.Order.Cancel)
				orders.PATCH("/:id/refund", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Order.Refund)
				orders.GET("/daily-summary", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Order.GetDailySummary)
			}

			// Payments
			payments := protected.Group("/payments")
			{
				payments.POST("/process", r.Payment.ProcessPayment)
				payments.GET("/:id", r.Payment.GetByID)
				payments.POST("/:id/refund", middleware.RoleMiddleware(model.RoleAdmin, model.RoleManager), r.Payment.Refund)
			}

			// Customers
			customers := protected.Group("/customers")
			{
				customers.GET("", r.Customer.GetAll)
				customers.GET("/:id", r.Customer.GetByID)
				customers.POST("", r.Customer.Create)
				customers.PUT("/:id", r.Customer.Update)
				customers.DELETE("/:id", middleware.RoleMiddleware(model.RoleAdmin), r.Customer.Delete)
			}
		}

		// Webhook (no auth - verified by signature)
		v1.POST("/payments/webhook", r.Payment.Webhook)
	}

	return engine
}
