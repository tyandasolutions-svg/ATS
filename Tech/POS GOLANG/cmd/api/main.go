package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/kosasen/pos-golang/internal/config"
	"github.com/kosasen/pos-golang/internal/handler"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/repository"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/database"
	"github.com/kosasen/pos-golang/pkg/logger"
	"go.uber.org/zap"
)

func main() {
	// Load config
	cfg, err := config.Load()
	if err != nil {
		panic("failed to load config: " + err.Error())
	}

	// Initialize logger
	log := logger.New(cfg.App.Env)
	defer log.Sync()

	log.Info("Starting POS Application",
		zap.String("app", cfg.App.Name),
		zap.String("env", cfg.App.Env),
		zap.String("port", cfg.App.Port),
	)

	// Connect to database
	db, err := database.NewConnection(&cfg.Database, log)
	if err != nil {
		log.Fatal("failed to connect to database", zap.Error(err))
	}

	// Auto-migrate
	if err := db.AutoMigrate(
		&model.User{},
		&model.Category{},
		&model.Product{},
		&model.Inventory{},
		&model.InventoryLog{},
		&model.Order{},
		&model.OrderItem{},
		&model.Payment{},
		&model.Customer{},
	); err != nil {
		log.Fatal("failed to auto-migrate", zap.Error(err))
	}
	log.Info("Database migration completed")

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	categoryRepo := repository.NewCategoryRepository(db)
	productRepo := repository.NewProductRepository(db)
	inventoryRepo := repository.NewInventoryRepository(db)
	orderRepo := repository.NewOrderRepository(db)
	paymentRepo := repository.NewPaymentRepository(db)
	customerRepo := repository.NewCustomerRepository(db)

	// Initialize services
	authSvc := service.NewAuthService(userRepo, &cfg.JWT, log)
	userSvc := service.NewUserService(userRepo, log)
	categorySvc := service.NewCategoryService(categoryRepo, log)
	productSvc := service.NewProductService(productRepo, inventoryRepo, log)
	inventorySvc := service.NewInventoryService(inventoryRepo, log)
	orderSvc := service.NewOrderService(orderRepo, productRepo, inventoryRepo, customerRepo, log)
	paymentSvc := service.NewPaymentService(paymentRepo, orderRepo, orderSvc, log)
	customerSvc := service.NewCustomerService(customerRepo, log)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authSvc)
	userHandler := handler.NewUserHandler(userSvc)
	categoryHandler := handler.NewCategoryHandler(categorySvc)
	productHandler := handler.NewProductHandler(productSvc)
	inventoryHandler := handler.NewInventoryHandler(inventorySvc)
	orderHandler := handler.NewOrderHandler(orderSvc)
	paymentHandler := handler.NewPaymentHandler(paymentSvc)
	customerHandler := handler.NewCustomerHandler(customerSvc)

	// Setup router
	router := handler.NewRouter(&handler.Router{
		Auth:      authHandler,
		User:      userHandler,
		Category:  categoryHandler,
		Product:   productHandler,
		Inventory: inventoryHandler,
		Order:     orderHandler,
		Payment:   paymentHandler,
		Customer:  customerHandler,
		JWTSecret: cfg.JWT.Secret,
	})

	// Start server
	srv := &http.Server{
		Addr:         ":" + cfg.App.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("failed to start server", zap.Error(err))
		}
	}()

	log.Info(fmt.Sprintf("Server started on port %s", cfg.App.Port))

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown", zap.Error(err))
	}

	log.Info("Server exited properly")
}
