package config

import (
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App      AppConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Payment  PaymentConfig
	Redis    RedisConfig
	RateLimit RateLimitConfig
}

type AppConfig struct {
	Port string
	Env  string
	Name string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

type JWTConfig struct {
	Secret        string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
}

type PaymentConfig struct {
	ServerKey string
	ClientKey string
	Env       string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
}

type RateLimitConfig struct {
	Requests int
	Duration time.Duration
}

func Load() (*Config, error) {
	viper.SetConfigFile(".env")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		// If no .env file, rely on environment variables
		viper.SetDefault("APP_PORT", "8080")
		viper.SetDefault("APP_ENV", "development")
		viper.SetDefault("APP_NAME", "POS-Golang")
		viper.SetDefault("DB_HOST", "localhost")
		viper.SetDefault("DB_PORT", "5432")
		viper.SetDefault("DB_USER", "postgres")
		viper.SetDefault("DB_PASSWORD", "postgres")
		viper.SetDefault("DB_NAME", "pos_golang")
		viper.SetDefault("DB_SSLMODE", "disable")
		viper.SetDefault("JWT_SECRET", "default-secret-change-me")
		viper.SetDefault("JWT_ACCESS_EXPIRY", "15m")
		viper.SetDefault("JWT_REFRESH_EXPIRY", "168h")
		viper.SetDefault("REDIS_HOST", "localhost")
		viper.SetDefault("REDIS_PORT", "6379")
		viper.SetDefault("RATE_LIMIT_REQUESTS", "100")
		viper.SetDefault("RATE_LIMIT_DURATION", "1m")
	}

	accessExpiry, _ := time.ParseDuration(viper.GetString("JWT_ACCESS_EXPIRY"))
	refreshExpiry, _ := time.ParseDuration(viper.GetString("JWT_REFRESH_EXPIRY"))
	rateLimitDuration, _ := time.ParseDuration(viper.GetString("RATE_LIMIT_DURATION"))

	config := &Config{
		App: AppConfig{
			Port: viper.GetString("APP_PORT"),
			Env:  viper.GetString("APP_ENV"),
			Name: viper.GetString("APP_NAME"),
		},
		Database: DatabaseConfig{
			Host:     viper.GetString("DB_HOST"),
			Port:     viper.GetString("DB_PORT"),
			User:     viper.GetString("DB_USER"),
			Password: viper.GetString("DB_PASSWORD"),
			Name:     viper.GetString("DB_NAME"),
			SSLMode:  viper.GetString("DB_SSLMODE"),
		},
		JWT: JWTConfig{
			Secret:        viper.GetString("JWT_SECRET"),
			AccessExpiry:  accessExpiry,
			RefreshExpiry: refreshExpiry,
		},
		Payment: PaymentConfig{
			ServerKey: viper.GetString("PAYMENT_SERVER_KEY"),
			ClientKey: viper.GetString("PAYMENT_CLIENT_KEY"),
			Env:       viper.GetString("PAYMENT_ENV"),
		},
		Redis: RedisConfig{
			Host:     viper.GetString("REDIS_HOST"),
			Port:     viper.GetString("REDIS_PORT"),
			Password: viper.GetString("REDIS_PASSWORD"),
		},
		RateLimit: RateLimitConfig{
			Requests: viper.GetInt("RATE_LIMIT_REQUESTS"),
			Duration: rateLimitDuration,
		},
	}

	return config, nil
}

func (c *DatabaseConfig) DSN() string {
	return "host=" + c.Host +
		" user=" + c.User +
		" password=" + c.Password +
		" dbname=" + c.Name +
		" port=" + c.Port +
		" sslmode=" + c.SSLMode +
		" TimeZone=Asia/Jakarta"
}
