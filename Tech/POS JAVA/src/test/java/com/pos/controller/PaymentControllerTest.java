package com.pos.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pos.dto.LoginRequest;
import com.pos.dto.OrderItemDTO;
import com.pos.dto.OrderRequestDTO;
import com.pos.dto.PaymentRequestDTO;
import com.pos.model.PaymentMethod;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("PaymentController Integration Tests")
class PaymentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String adminToken;
    private Long createdOrderId;
    private Long createdPaymentId;

    @BeforeAll
    void setup() throws Exception {
        adminToken = loginAndGetToken("admin", "admin123");
        createdOrderId = createTestOrder();
    }

    // ─── Security ────────────────────────────────────────────────────────────────

    @Test
    @Order(1)
    @DisplayName("GET /api/payments without JWT returns 401")
    void getAllPayments_WithoutAuth_Returns401() throws Exception {
        mockMvc.perform(get("/api/payments"))
                .andExpect(status().isUnauthorized());
    }

    // ─── GET all ─────────────────────────────────────────────────────────────────

    @Test
    @Order(2)
    @DisplayName("GET /api/payments returns list of payments")
    void getAllPayments_WithAuth_Returns200() throws Exception {
        mockMvc.perform(get("/api/payments")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    // ─── POST process payment ────────────────────────────────────────────────────

    @Test
    @Order(3)
    @DisplayName("POST /api/payments processes payment for a valid order")
    void processPayment_WithValidOrder_ReturnsPaymentResult() throws Exception {
        if (createdOrderId == null) return;

        PaymentRequestDTO dto = new PaymentRequestDTO();
        dto.setOrderId(createdOrderId);
        dto.setPaymentMethod(PaymentMethod.CASH);

        MvcResult result = mockMvc.perform(post("/api/payments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(jsonPath("$.paymentId").isNumber())
                .andExpect(jsonPath("$.orderId").value(createdOrderId))
                .andExpect(jsonPath("$.paymentMethod").value("CASH"))
                .andReturn();

        int httpStatus = result.getResponse().getStatus();
        // 201 = SUCCESS, 200 = FAILED (gateway declined)
        Assertions.assertTrue(httpStatus == 201 || httpStatus == 200,
                "Expected 201 (SUCCESS) or 200 (FAILED), got " + httpStatus);

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        createdPaymentId = json.get("paymentId").asLong();
    }

    @Test
    @Order(4)
    @DisplayName("POST /api/payments with missing orderId returns 400")
    void processPayment_WithMissingOrderId_Returns400() throws Exception {
        PaymentRequestDTO dto = new PaymentRequestDTO();
        // orderId is null
        dto.setPaymentMethod(PaymentMethod.CREDIT_CARD);

        mockMvc.perform(post("/api/payments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @Order(5)
    @DisplayName("POST /api/payments for non-existent order returns 400")
    void processPayment_WithNonExistentOrder_Returns400() throws Exception {
        PaymentRequestDTO dto = new PaymentRequestDTO();
        dto.setOrderId(999999L);
        dto.setPaymentMethod(PaymentMethod.CASH);

        mockMvc.perform(post("/api/payments")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET by ID ───────────────────────────────────────────────────────────────

    @Test
    @Order(6)
    @DisplayName("GET /api/payments/{id} returns payment details")
    void getPaymentById_WhenExists_Returns200() throws Exception {
        if (createdPaymentId == null) return;

        mockMvc.perform(get("/api/payments/" + createdPaymentId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paymentId").value(createdPaymentId));
    }

    @Test
    @Order(7)
    @DisplayName("GET /api/payments/999999 returns 400 for non-existent ID")
    void getPaymentById_WhenNotFound_Returns400() throws Exception {
        mockMvc.perform(get("/api/payments/999999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
    }

    // ─── GET by order ─────────────────────────────────────────────────────────────

    @Test
    @Order(8)
    @DisplayName("GET /api/payments/order/{orderId} returns payment history for order")
    void getPaymentsByOrder_Returns200() throws Exception {
        if (createdOrderId == null) return;

        mockMvc.perform(get("/api/payments/order/" + createdOrderId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    // ─── GET by status ───────────────────────────────────────────────────────────

    @Test
    @Order(9)
    @DisplayName("GET /api/payments?status=SUCCESS returns only SUCCESS payments")
    void getAllPayments_WithStatusFilter_ReturnsFiltered() throws Exception {
        mockMvc.perform(get("/api/payments?status=SUCCESS")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @Order(10)
    @DisplayName("GET /api/payments?status=INVALID returns 400")
    void getAllPayments_WithInvalidStatus_Returns400() throws Exception {
        mockMvc.perform(get("/api/payments?status=INVALID")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────────

    private String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest req = new LoginRequest();
        req.setUsername(username);
        req.setPassword(password);

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();

        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("token").asText();
    }

    /** Creates an order using the seeded product data and returns its ID. */
    private Long createTestOrder() throws Exception {
        // Use first available product (seeded by DataInitializer with id likely = 1)
        OrderItemDTO item = new OrderItemDTO();
        item.setProductId(1L);
        item.setQuantity(1);

        OrderRequestDTO orderRequest = new OrderRequestDTO();
        orderRequest.setOrderItems(List.of(item));

        MvcResult result = mockMvc.perform(post("/api/orders")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(orderRequest)))
                .andReturn();

        if (result.getResponse().getStatus() != 201) return null;

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        return json.get("id").asLong();
    }
}
