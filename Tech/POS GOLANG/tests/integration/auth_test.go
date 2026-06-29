package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/kosasen/pos-golang/internal/model"
)

func TestRegisterEndpoint(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name       string
		body       model.RegisterRequest
		wantStatus int
	}{
		{
			name: "valid registration",
			body: model.RegisterRequest{
				Name:     "Test User",
				Email:    "test@example.com",
				Password: "password123",
				Phone:    "081234567890",
			},
			wantStatus: http.StatusCreated,
		},
		{
			name: "missing email",
			body: model.RegisterRequest{
				Name:     "Test User",
				Password: "password123",
			},
			wantStatus: http.StatusBadRequest,
		},
		{
			name: "short password",
			body: model.RegisterRequest{
				Name:     "Test User",
				Email:    "test@example.com",
				Password: "short",
			},
			wantStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")

			w := httptest.NewRecorder()

			// Note: This is a skeleton test. Full integration tests
			// require a test database and service setup.
			_ = w
			_ = req
		})
	}
}

func TestLoginEndpoint(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name       string
		body       model.LoginRequest
		wantStatus int
	}{
		{
			name: "valid login",
			body: model.LoginRequest{
				Email:    "test@example.com",
				Password: "password123",
			},
			wantStatus: http.StatusOK,
		},
		{
			name: "invalid email",
			body: model.LoginRequest{
				Email:    "invalid",
				Password: "password123",
			},
			wantStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")

			w := httptest.NewRecorder()
			_ = w
			_ = req
		})
	}
}
