package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/response"
)

type InventoryHandler struct {
	inventoryService service.InventoryService
}

func NewInventoryHandler(inventoryService service.InventoryService) *InventoryHandler {
	return &InventoryHandler{inventoryService: inventoryService}
}

func (h *InventoryHandler) GetAll(c *gin.Context) {
	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	inventories, total, err := h.inventoryService.GetAll(c.Request.Context(), &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "inventory retrieved", inventories, meta)
}

func (h *InventoryHandler) GetByProductID(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("product_id"))
	if err != nil {
		response.BadRequest(c, "invalid product ID", nil)
		return
	}

	inventory, err := h.inventoryService.GetByProductID(c.Request.Context(), productID)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "inventory retrieved", inventory)
}

func (h *InventoryHandler) StockIn(c *gin.Context) {
	var req model.StockInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		response.Unauthorized(c, "unauthorized")
		return
	}

	if err := h.inventoryService.StockIn(c.Request.Context(), userID, &req); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "stock added successfully", nil)
}

func (h *InventoryHandler) StockOut(c *gin.Context) {
	var req model.StockOutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		response.Unauthorized(c, "unauthorized")
		return
	}

	if err := h.inventoryService.StockOut(c.Request.Context(), userID, &req); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "stock removed successfully", nil)
}

func (h *InventoryHandler) StockAdjustment(c *gin.Context) {
	var req model.StockAdjustmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	userID, err := getUserID(c)
	if err != nil {
		response.Unauthorized(c, "unauthorized")
		return
	}

	if err := h.inventoryService.StockAdjustment(c.Request.Context(), userID, &req); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "stock adjusted successfully", nil)
}

func (h *InventoryHandler) GetAlerts(c *gin.Context) {
	alerts, err := h.inventoryService.GetAlerts(c.Request.Context())
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "low stock alerts", alerts)
}

func (h *InventoryHandler) GetLogs(c *gin.Context) {
	productID, err := uuid.Parse(c.Query("product_id"))
	if err != nil {
		response.BadRequest(c, "product_id query parameter is required", nil)
		return
	}

	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	logs, total, err := h.inventoryService.GetLogs(c.Request.Context(), productID, &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "inventory logs retrieved", logs, meta)
}
