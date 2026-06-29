package main

import (
	"fmt"
	"os"

	"github.com/kosasen/pos-golang/internal/config"
	"github.com/kosasen/pos-golang/migrations"
	"github.com/kosasen/pos-golang/pkg/database"
	"github.com/kosasen/pos-golang/pkg/logger"
	"go.uber.org/zap"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic("failed to load config: " + err.Error())
	}

	log := logger.New(cfg.App.Env)
	defer log.Sync()

	db, err := database.NewConnection(&cfg.Database, log)
	if err != nil {
		log.Fatal("failed to connect to database", zap.Error(err))
	}

	if len(os.Args) < 2 {
		fmt.Println("Usage: go run ./cmd/migrate/main.go [up|seed]")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "up":
		log.Info("Running migrations...")
		if err := migrations.Migrate(db); err != nil {
			log.Fatal("migration failed", zap.Error(err))
		}
		log.Info("Migrations completed successfully")

	case "seed":
		log.Info("Seeding database...")
		if err := migrations.Seed(db); err != nil {
			log.Fatal("seeding failed", zap.Error(err))
		}
		log.Info("Seeding completed successfully")

	default:
		fmt.Printf("Unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}
