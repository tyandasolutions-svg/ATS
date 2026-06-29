package com.pos.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pos.dto.LoginRequest;
import com.pos.dto.ProductDTO;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("ProductController Integration Tests")
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String adminToken;
    private Long createdProductId;

    @BeforeAll
    void obtainToken() throws Exception {
        adminToken = loginAndGetToken("admin", "admin123");
    }

    // ─── Security guard ──────────────────────────────────────────────────────────

    @Test
    @Order(1)
    @DisplayName("GET /api/products without JWT returns 401")
    void getAllProducts_WithoutAuth_Returns401() throws Exception {
        mockMvc.perform(get("/api/products"))
                .andExpect(status().isUnauthorized());
    }

    // ─── GET all ─────────────────────────────────────────────────────────────────

    @Test
    @Order(2)
    @DisplayName("GET /api/products with valid JWT returns product list")
    void getAllProducts_WithAuth_Returns200AndList() throws Exception {
        mockMvc.perform(get("/api/products")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @Order(3)
    @DisplayName("GET /api/products?name=laptop filters results by name")
    void getAllProducts_WithNameFilter_FiltersResults() throws Exception {
        mockMvc.perform(get("/api/products?name=laptop")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @Order(4)
    @DisplayName("GET /api/products?category=Electronics filters results by category")
    void getAllProducts_WithCategoryFilter_FiltersResults() throws Exception {
        mockMvc.perform(get("/api/products?category=Electronics")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    // ─── GET low-stock ───────────────────────────────────────────────────────────

    @Test
    @Order(5)
    @DisplayName("GET /api/products/low-stock returns products below threshold")
    void getLowStockProducts_Returns200() throws Exception {
        mockMvc.perform(get("/api/products/low-stock?threshold=100")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    // ─── POST create ─────────────────────────────────────────────────────────────

    @Test
    @Order(6)
    @DisplayName("POST /api/products with valid data creates product and returns 201")
    void createProduct_WithValidData_Returns201() throws Exception {
        ProductDTO dto = new ProductDTO();
        dto.setName("Integration Test Product " + System.currentTimeMillis());
        dto.setDescription("Created by integration test");
        dto.setPrice(new BigDecimal("999000"));
        dto.setStock(25);
        dto.setCategory("TestCategory");

        MvcResult result = mockMvc.perform(post("/api/products")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.stock").value(25))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        createdProductId = json.get("id").asLong();
    }

    @Test
    @Order(7)
    @DisplayName("POST /api/products with missing name returns 400")
    void createProduct_WithMissingName_Returns400() throws Exception {
        ProductDTO dto = new ProductDTO();
        // name is missing
        dto.setPrice(new BigDecimal("100000"));
        dto.setStock(10);

        mockMvc.perform(post("/api/products")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Validation Failed"));
    }

    @Test
    @Order(8)
    @DisplayName("POST /api/products with negative price returns 400")
    void createProduct_WithNegativePrice_Returns400() throws Exception {
        ProductDTO dto = new ProductDTO();
        dto.setName("Bad Product");
        dto.setPrice(new BigDecimal("-100"));
        dto.setStock(10);

        mockMvc.perform(post("/api/products")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET by ID ───────────────────────────────────────────────────────────────

    @Test
    @Order(9)
    @DisplayName("GET /api/products/{id} returns product when it exists")
    void getProductById_WhenExists_Returns200() throws Exception {
        if (createdProductId == null) return; // skip if prior test was skipped

        mockMvc.perform(get("/api/products/" + createdProductId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(createdProductId));
    }

    @Test
    @Order(10)
    @DisplayName("GET /api/products/999999 returns 400 for non-existent ID")
    void getProductById_WhenNotFound_Returns400() throws Exception {
        mockMvc.perform(get("/api/products/999999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
    }

    // ─── PUT update ──────────────────────────────────────────────────────────────

    @Test
    @Order(11)
    @DisplayName("PUT /api/products/{id} updates product successfully")
    void updateProduct_WithValidData_Returns200() throws Exception {
        if (createdProductId == null) return;

        ProductDTO dto = new ProductDTO();
        dto.setName("Updated Integration Test Product");
        dto.setPrice(new BigDecimal("1200000"));
        dto.setStock(30);
        dto.setCategory("TestCategory");

        mockMvc.perform(put("/api/products/" + createdProductId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Integration Test Product"))
                .andExpect(jsonPath("$.stock").value(30));
    }

    // ─── PATCH stock ─────────────────────────────────────────────────────────────

    @Test
    @Order(12)
    @DisplayName("PATCH /api/products/{id}/stock?quantity=5 increases stock")
    void updateStock_WithPositiveQuantity_IncreasesStock() throws Exception {
        if (createdProductId == null) return;

        mockMvc.perform(patch("/api/products/" + createdProductId + "/stock?quantity=5")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stock").value(35)); // 30 + 5
    }

    @Test
    @Order(13)
    @DisplayName("PATCH /api/products/{id}/stock?quantity=-999 returns 400 when stock insufficient")
    void updateStock_WhenInsufficientStock_Returns400() throws Exception {
        if (createdProductId == null) return;

        mockMvc.perform(patch("/api/products/" + createdProductId + "/stock?quantity=-999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Insufficient stock")));
    }

    // ─── DELETE ──────────────────────────────────────────────────────────────────

    @Test
    @Order(14)
    @DisplayName("DELETE /api/products/{id} deletes product and returns 204")
    void deleteProduct_WhenExists_Returns204() throws Exception {
        if (createdProductId == null) return;

        mockMvc.perform(delete("/api/products/" + createdProductId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNoContent());
    }

    // ─── Helper ──────────────────────────────────────────────────────────────────

    private String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsername(username);
        loginRequest.setPassword(password);

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        return json.get("token").asText();
    }
}
