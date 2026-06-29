package com.pos.service;

import com.pos.dto.PaymentRequestDTO;
import com.pos.dto.PaymentResponseDTO;
import com.pos.model.*;
import com.pos.repository.PaymentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("PaymentService Unit Tests")
class PaymentServiceTest {

    @InjectMocks
    private PaymentService paymentService;

    @Mock
    private PaymentRepository paymentRepository;

    @Mock
    private OrderService orderService;

    private Order sampleOrder;
    private Payment samplePayment;

    @BeforeEach
    void setUp() {
        sampleOrder = new Order();
        sampleOrder.setId(1L);
        sampleOrder.setOrderNumber("ORD-20260629120000-999");
        sampleOrder.setStatus(OrderStatus.PENDING);
        sampleOrder.setTotalAmount(new BigDecimal("15000000"));
        sampleOrder.setOrderItems(new ArrayList<>());

        samplePayment = new Payment();
        samplePayment.setId(1L);
        samplePayment.setOrder(sampleOrder);
        samplePayment.setAmount(new BigDecimal("15000000"));
        samplePayment.setPaymentMethod(PaymentMethod.CASH);
        samplePayment.setPaymentStatus(PaymentStatus.SUCCESS);
        samplePayment.setTransactionId("TXN-ABCDEFABCDEF");
        samplePayment.setGatewayResponse("{\"status\":\"APPROVED\"}");
        samplePayment.setPaidAt(LocalDateTime.now());
    }

    // ─── getPaymentById ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("getPaymentById returns response DTO when payment exists")
    void getPaymentById_WhenExists_ReturnsDTO() {
        when(paymentRepository.findById(1L)).thenReturn(Optional.of(samplePayment));

        PaymentResponseDTO result = paymentService.getPaymentById(1L);

        assertThat(result.getPaymentId()).isEqualTo(1L);
        assertThat(result.getTransactionId()).isEqualTo("TXN-ABCDEFABCDEF");
        assertThat(result.isSuccess()).isTrue();
    }

    @Test
    @DisplayName("getPaymentById throws RuntimeException when payment not found")
    void getPaymentById_WhenNotFound_ThrowsRuntimeException() {
        when(paymentRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.getPaymentById(99L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Payment not found with id: 99");
    }

    // ─── getPaymentsByOrderId ─────────────────────────────────────────────────────

    @Test
    @DisplayName("getPaymentsByOrderId returns all payments for the order")
    void getPaymentsByOrderId_ReturnsList() {
        when(paymentRepository.findByOrderId(1L)).thenReturn(List.of(samplePayment));

        List<PaymentResponseDTO> result = paymentService.getPaymentsByOrderId(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getOrderId()).isEqualTo(1L);
    }

    // ─── processPayment ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("processPayment throws when order is CANCELLED")
    void processPayment_WhenOrderCancelled_ThrowsRuntimeException() {
        sampleOrder.setStatus(OrderStatus.CANCELLED);

        PaymentRequestDTO requestDTO = new PaymentRequestDTO();
        requestDTO.setOrderId(1L);
        requestDTO.setPaymentMethod(PaymentMethod.CASH);

        when(orderService.getOrderById(1L)).thenReturn(sampleOrder);

        assertThatThrownBy(() -> paymentService.processPayment(requestDTO))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("CANCELLED");
    }

    @Test
    @DisplayName("processPayment throws when order is already COMPLETED")
    void processPayment_WhenOrderCompleted_ThrowsRuntimeException() {
        sampleOrder.setStatus(OrderStatus.COMPLETED);

        PaymentRequestDTO requestDTO = new PaymentRequestDTO();
        requestDTO.setOrderId(1L);
        requestDTO.setPaymentMethod(PaymentMethod.CREDIT_CARD);

        when(orderService.getOrderById(1L)).thenReturn(sampleOrder);

        assertThatThrownBy(() -> paymentService.processPayment(requestDTO))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("COMPLETED");
    }

    @Test
    @DisplayName("processPayment throws when successful payment already exists for the order")
    void processPayment_WhenAlreadyPaid_ThrowsRuntimeException() {
        PaymentRequestDTO requestDTO = new PaymentRequestDTO();
        requestDTO.setOrderId(1L);
        requestDTO.setPaymentMethod(PaymentMethod.DEBIT_CARD);

        when(orderService.getOrderById(1L)).thenReturn(sampleOrder);
        when(paymentRepository.findByOrderIdAndPaymentStatus(1L, PaymentStatus.SUCCESS))
                .thenReturn(Optional.of(samplePayment));

        assertThatThrownBy(() -> paymentService.processPayment(requestDTO))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("already has a successful payment");
    }

    @Test
    @DisplayName("processPayment creates a payment record and returns DTO")
    void processPayment_WithValidOrder_CreatesPaymentRecord() {
        PaymentRequestDTO requestDTO = new PaymentRequestDTO();
        requestDTO.setOrderId(1L);
        requestDTO.setPaymentMethod(PaymentMethod.BANK_TRANSFER);

        when(orderService.getOrderById(1L)).thenReturn(sampleOrder);
        when(paymentRepository.findByOrderIdAndPaymentStatus(1L, PaymentStatus.SUCCESS))
                .thenReturn(Optional.empty());
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> {
            Payment p = inv.getArgument(0);
            p.setId(1L);
            // Simulate gateway filling transactionId
            if (p.getTransactionId() == null) {
                p.setTransactionId("TXN-MOCK123456");
                p.setGatewayResponse("{\"status\":\"APPROVED\"}");
                p.setPaymentStatus(PaymentStatus.SUCCESS);
                p.setPaidAt(LocalDateTime.now());
            }
            return p;
        });

        PaymentResponseDTO result = paymentService.processPayment(requestDTO);

        assertThat(result).isNotNull();
        assertThat(result.getPaymentId()).isEqualTo(1L);
        // Payment record creation is verified
        verify(paymentRepository, atLeastOnce()).save(any(Payment.class));
    }

    // ─── refundPayment ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("refundPayment changes status to REFUNDED and cancels order")
    void refundPayment_WhenSuccess_RefundsAndCancelsOrder() {
        when(paymentRepository.findById(1L)).thenReturn(Optional.of(samplePayment));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(i -> i.getArguments()[0]);
        when(orderService.updateOrderStatus(eq(1L), eq(OrderStatus.CANCELLED)))
                .thenReturn(sampleOrder);

        PaymentResponseDTO result = paymentService.refundPayment(1L);

        assertThat(result.getPaymentStatus()).isEqualTo(PaymentStatus.REFUNDED);
        verify(orderService).updateOrderStatus(eq(1L), eq(OrderStatus.CANCELLED));
    }

    @Test
    @DisplayName("refundPayment throws when payment is not in SUCCESS status")
    void refundPayment_WhenNotSuccess_ThrowsRuntimeException() {
        samplePayment.setPaymentStatus(PaymentStatus.FAILED);
        when(paymentRepository.findById(1L)).thenReturn(Optional.of(samplePayment));

        assertThatThrownBy(() -> paymentService.refundPayment(1L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Only SUCCESS payments can be refunded");
    }

    @Test
    @DisplayName("refundPayment throws when payment not found")
    void refundPayment_WhenNotFound_ThrowsRuntimeException() {
        when(paymentRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.refundPayment(99L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Payment not found with id: 99");
    }

    // ─── getAllPayments ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("getAllPayments returns list of response DTOs")
    void getAllPayments_ReturnsList() {
        when(paymentRepository.findAll()).thenReturn(List.of(samplePayment));

        List<PaymentResponseDTO> result = paymentService.getAllPayments();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getOrderNumber()).isEqualTo("ORD-20260629120000-999");
    }
}
