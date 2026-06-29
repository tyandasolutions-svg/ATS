package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/response"
)

type OrderHandler struct {
	orderService service.OrderService
}

func NewOrderHandler(orderService service.OrderService) *OrderHandler {
	return &OrderHandler{orderService: orderService}
}

func (h *OrderHandler) Create(c *gin.Context) {
	var req model.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		response.Unauthorized(c, "unauthorized")
		return
	}

	order, err := h.orderService.Create(c.Request.Context(), userID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusCreated, "order created", order)
}

func (h *OrderHandler) GetAll(c *gin.Context) {
	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	orders, total, err := h.orderService.GetAll(c.Request.Context(), &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "orders retrieved", orders, meta)
}

func (h *OrderHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid order ID", nil)
		return
	}

	order, err := h.orderService.GetByID(c.Request.Context(), id)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "order retrieved", order)
}

func (h *OrderHandler) Cancel(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid order ID", nil)
		return
	}

	if err := h.orderService.Cancel(c.Request.Context(), id); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "order cancelled", nil)
}

func (h *OrderHandler) Refund(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid order ID", nil)
		return
	}

	if err := h.orderService.Refund(c.Request.Context(), id); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "order refunded", nil)
}

func (h *OrderHandler) GetDailySummary(c *gin.Context) {
	date := c.Query("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}

	summary, err := h.orderService.GetDailySummary(c.Request.Context(), date)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "daily summary", summary)
}
