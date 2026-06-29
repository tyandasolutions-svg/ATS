package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/response"
)

type CustomerHandler struct {
	customerService service.CustomerService
}

func NewCustomerHandler(customerService service.CustomerService) *CustomerHandler {
	return &CustomerHandler{customerService: customerService}
}

func (h *CustomerHandler) Create(c *gin.Context) {
	var req model.CreateCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	customer, err := h.customerService.Create(c.Request.Context(), &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusCreated, "customer created", customer)
}

func (h *CustomerHandler) GetAll(c *gin.Context) {
	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	customers, total, err := h.customerService.GetAll(c.Request.Context(), &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "customers retrieved", customers, meta)
}

func (h *CustomerHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid customer ID", nil)
		return
	}

	customer, err := h.customerService.GetByID(c.Request.Context(), id)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "customer retrieved", customer)
}

func (h *CustomerHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid customer ID", nil)
		return
	}

	var req model.UpdateCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	customer, err := h.customerService.Update(c.Request.Context(), id, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "customer updated", customer)
}

func (h *CustomerHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid customer ID", nil)
		return
	}

	if err := h.customerService.Delete(c.Request.Context(), id); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "customer deleted", nil)
}
