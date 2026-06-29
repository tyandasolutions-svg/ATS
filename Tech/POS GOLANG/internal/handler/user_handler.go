package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/response"
)

type UserHandler struct {
	userService service.UserService
}

func NewUserHandler(userService service.UserService) *UserHandler {
	return &UserHandler{userService: userService}
}

func (h *UserHandler) GetAll(c *gin.Context) {
	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	users, total, err := h.userService.GetAll(c.Request.Context(), &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "users retrieved", users, meta)
}

func (h *UserHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid user ID", nil)
		return
	}

	user, err := h.userService.GetByID(c.Request.Context(), id)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "user retrieved", user)
}

func (h *UserHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid user ID", nil)
		return
	}

	var req struct {
		Name  string `json:"name"`
		Phone string `json:"phone"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	user, err := h.userService.Update(c.Request.Context(), id, req.Name, req.Phone)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "user updated", user)
}

func (h *UserHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid user ID", nil)
		return
	}

	if err := h.userService.Deactivate(c.Request.Context(), id); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "user deactivated", nil)
}

func (h *UserHandler) AssignRole(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid user ID", nil)
		return
	}

	var req struct {
		Role model.Role `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	if err := h.userService.AssignRole(c.Request.Context(), id, req.Role); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "role assigned", nil)
}
