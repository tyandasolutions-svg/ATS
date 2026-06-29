package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kosasen/pos-golang/internal/model"
	"github.com/kosasen/pos-golang/internal/service"
	"github.com/kosasen/pos-golang/pkg/response"
)

type ProductHandler struct {
	productService service.ProductService
}

func NewProductHandler(productService service.ProductService) *ProductHandler {
	return &ProductHandler{productService: productService}
}

func (h *ProductHandler) Create(c *gin.Context) {
	var req model.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	product, err := h.productService.Create(c.Request.Context(), &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusCreated, "product created", product)
}

func (h *ProductHandler) GetAll(c *gin.Context) {
	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	products, total, err := h.productService.GetAll(c.Request.Context(), &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "products retrieved", products, meta)
}

func (h *ProductHandler) GetByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid product ID", nil)
		return
	}

	product, err := h.productService.GetByID(c.Request.Context(), id)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "product retrieved", product)
}

func (h *ProductHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid product ID", nil)
		return
	}

	var req model.UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body", err.Error())
		return
	}

	product, err := h.productService.Update(c.Request.Context(), id, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "product updated", product)
}

func (h *ProductHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid product ID", nil)
		return
	}

	if err := h.productService.Delete(c.Request.Context(), id); err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "product deleted", nil)
}

func (h *ProductHandler) Search(c *gin.Context) {
	keyword := c.Query("q")
	if keyword == "" {
		response.BadRequest(c, "search query is required", nil)
		return
	}

	var query model.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		response.BadRequest(c, "invalid query parameters", err.Error())
		return
	}
	query.SetDefaults()

	products, total, err := h.productService.Search(c.Request.Context(), keyword, &query)
	if err != nil {
		handleError(c, err)
		return
	}

	meta := buildMeta(query.Page, query.PerPage, total)
	response.SuccessWithMeta(c, http.StatusOK, "products found", products, meta)
}

func (h *ProductHandler) GetLowStock(c *gin.Context) {
	products, err := h.productService.GetLowStock(c.Request.Context())
	if err != nil {
		handleError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "low stock products", products)
}
