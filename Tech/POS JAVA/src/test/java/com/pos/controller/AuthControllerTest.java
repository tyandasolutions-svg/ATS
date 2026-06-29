package com.pos.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pos.dto.LoginRequest;
import com.pos.dto.RegisterRequest;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@DisplayName("AuthController Integration Tests")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    // ─── Login ───────────────────────────────────────────────────────────────────

    @Test
    @Order(1)
    @DisplayName("POST /api/auth/login with valid credentials returns JWT token")
    void login_WithValidCredentials_ReturnsJwtToken() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsername("admin");
        request.setPassword("admin123");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.username").value("admin"))
                .andExpect(jsonPath("$.role").value("ADMIN"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(response.get("token").asText()).isNotBlank();
    }

    @Test
    @Order(2)
    @DisplayName("POST /api/auth/login with wrong password returns 401")
    void login_WithWrongPassword_Returns401() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsername("admin");
        request.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @Order(3)
    @DisplayName("POST /api/auth/login with blank fields returns 400")
    void login_WithBlankFields_Returns400() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsername("");
        request.setPassword("");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @Order(4)
    @DisplayName("POST /api/auth/login with unknown user returns 401")
    void login_WithUnknownUser_Returns401() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsername("nonexistent");
        request.setPassword("somepassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    // ─── Register ────────────────────────────────────────────────────────────────

    @Test
    @Order(5)
    @DisplayName("POST /api/auth/register with valid data creates new user")
    void register_WithValidData_Returns200() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("newstaff_" + System.currentTimeMillis());
        request.setPassword("pass1234");
        request.setEmail("newstaff@pos.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("User registered successfully"));
    }

    @Test
    @Order(6)
    @DisplayName("POST /api/auth/register with existing username returns 400")
    void register_WithExistingUsername_Returns400() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("admin"); // already exists
        request.setPassword("somepass");
        request.setEmail("admin2@pos.com");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Username is already taken"));
    }

    @Test
    @Order(7)
    @DisplayName("POST /api/auth/register with short password returns 400")
    void register_WithShortPassword_Returns400() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("shortpwduser");
        request.setPassword("abc"); // too short (min 6)

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET /me ─────────────────────────────────────────────────────────────────

    @Test
    @Order(8)
    @DisplayName("GET /api/auth/me without token returns 401")
    void getCurrentUser_WithoutToken_Returns401() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @Order(9)
    @DisplayName("GET /api/auth/me with valid token returns username and role")
    void getCurrentUser_WithValidToken_ReturnsUserInfo() throws Exception {
        String token = obtainToken("admin", "admin123");

        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("admin"))
                .andExpect(jsonPath("$.role").value("ADMIN"));
    }

    // ─── Logout ──────────────────────────────────────────────────────────────────

    @Test
    @Order(10)
    @DisplayName("POST /api/auth/logout with valid token returns success message")
    void logout_WithValidToken_ReturnsSuccessMessage() throws Exception {
        String token = obtainToken("cashier", "cashier123");

        mockMvc.perform(post("/api/auth/logout")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Logged out successfully"));
    }

    // ─── Helper ──────────────────────────────────────────────────────────────────

    private String obtainToken(String username, String password) throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsername(username);
        request.setPassword(password);

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        return json.get("token").asText();
    }
}
