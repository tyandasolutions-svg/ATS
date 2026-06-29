package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/pkg/response"
)

func getUserID(c *gin.Context) (uuid.UUID, error) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		return uuid.UUID{}, model.NewUnauthorizedError("unauthorized")
	}
	return uuid.Parse(userIDStr.(string))
}

func handleError(c *gin.Context, err error) {
	if appErr, ok := err.(*model.AppError); ok {
		switch appErr.Code {
		case 400:
			response.BadRequest(c, appErr.Message, nil)
		case 401:
			response.Unauthorized(c, appErr.Message)
		case 403:
			response.Forbidden(c, appErr.Message)
		case 404:
			response.NotFound(c, appErr.Message)
		case 409:
			response.Conflict(c, appErr.Message)
		default:
			response.InternalError(c, appErr.Message)
		}
		return
	}
	response.InternalError(c, "internal server error")
}

func buildMeta(page, perPage int, total int64) *response.Meta {
	totalPages := total / int64(perPage)
	if total%int64(perPage) > 0 {
		totalPages++
	}
	return &response.Meta{
		Page:       page,
		PerPage:    perPage,
		Total:      total,
		TotalPages: totalPages,
	}
}
