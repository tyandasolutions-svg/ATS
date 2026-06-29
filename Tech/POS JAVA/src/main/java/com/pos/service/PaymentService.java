package com.pos.service;

import com.pos.dto.PaymentRequestDTO;
import com.pos.dto.PaymentResponseDTO;
import com.pos.model.*;
import com.pos.repository.PaymentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Service
@Transactional
public class PaymentService {

    private static final Logger logger = LoggerFactory.getLogger(PaymentService.class);

    /** Simulated gateway success rate (0–100). Change to 100 for guaranteed success in demos. */
    private static final int GATEWAY_SUCCESS_RATE_PERCENT = 90;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private OrderService orderService;

    // ─── Queries ────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<PaymentResponseDTO> getAllPayments() {
        return paymentRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PaymentResponseDTO getPaymentById(Long id) {
        Payment payment = findPaymentById(id);
        return mapToResponseDTO(payment);
    }

    @Transactional(readOnly = true)
    public List<PaymentResponseDTO> getPaymentsByOrderId(Long orderId) {
        return paymentRepository.findByOrderId(orderId).stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PaymentResponseDTO> getPaymentsByStatus(PaymentStatus status) {
        return paymentRepository.findByPaymentStatus(status).stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    // ─── Mutations ──────────────────────────────────────────────────────────────

    /**
     * Processes a payment for the given order through the simulated payment gateway.
     * <p>
     * Flow:
     * <ol>
     *   <li>Validate the order exists and is payable (not CANCELLED / COMPLETED).</li>
     *   <li>Guard against duplicate successful payments on the same order.</li>
     *   <li>Persist a PROCESSING payment record.</li>
     *   <li>Invoke the simulated gateway (90 % success rate).</li>
     *   <li>Update payment status; on SUCCESS → confirm the order.</li>
     * </ol>
     */
    public PaymentResponseDTO processPayment(PaymentRequestDTO requestDTO) {
        Order order = orderService.getOrderById(requestDTO.getOrderId());

        validateOrderIsPayable(order);

        // Guard: only one successful payment per order
        paymentRepository.findByOrderIdAndPaymentStatus(order.getId(), PaymentStatus.SUCCESS)
                .ifPresent(p -> {
                    throw new RuntimeException(
                            "Order already has a successful payment. Transaction ID: " + p.getTransactionId());
                });

        // Create initial PROCESSING record so the attempt is always traceable
        Payment payment = new Payment();
        payment.setOrder(order);
        payment.setAmount(order.getTotalAmount());
        payment.setPaymentMethod(requestDTO.getPaymentMethod());
        payment.setPaymentStatus(PaymentStatus.PROCESSING);
        payment = paymentRepository.save(payment);

        logger.info("Initiating payment [id={}] for order [{}] via [{}]",
                payment.getId(), order.getOrderNumber(), requestDTO.getPaymentMethod());

        // Simulate gateway call
        GatewayResult result = simulatePaymentGateway(requestDTO.getPaymentMethod(), order.getTotalAmount());

        payment.setTransactionId(result.transactionId());
        payment.setGatewayResponse(result.responseJson());

        if (result.success()) {
            payment.setPaymentStatus(PaymentStatus.SUCCESS);
            payment.setPaidAt(LocalDateTime.now());
            orderService.updateOrderStatus(order.getId(), OrderStatus.CONFIRMED);
            logger.info("Payment [id={}] SUCCESS. Transaction: {}", payment.getId(), result.transactionId());
        } else {
            payment.setPaymentStatus(PaymentStatus.FAILED);
            logger.warn("Payment [id={}] FAILED. Reason: {}", payment.getId(), result.declineReason());
        }

        return mapToResponseDTO(paymentRepository.save(payment));
    }

    /**
     * Refunds a previously successful payment and cancels the associated order
     * (which automatically restores product stock via {@code OrderService}).
     */
    public PaymentResponseDTO refundPayment(Long paymentId) {
        Payment payment = findPaymentById(paymentId);

        if (payment.getPaymentStatus() != PaymentStatus.SUCCESS) {
            throw new RuntimeException(
                    "Only SUCCESS payments can be refunded. Current status: " + payment.getPaymentStatus());
        }

        String refundRef = "REFUND-" + payment.getTransactionId();
        payment.setPaymentStatus(PaymentStatus.REFUNDED);
        payment.setGatewayResponse(payment.getGatewayResponse()
                + " | REFUNDED [" + refundRef + "] at " + LocalDateTime.now());

        // Cancelling the order also restores product stock automatically
        orderService.updateOrderStatus(payment.getOrder().getId(), OrderStatus.CANCELLED);

        logger.info("Payment [id={}] REFUNDED. Order [{}] CANCELLED.",
                paymentId, payment.getOrder().getOrderNumber());

        return mapToResponseDTO(paymentRepository.save(payment));
    }

    // ─── Gateway Simulation ─────────────────────────────────────────────────────

    private GatewayResult simulatePaymentGateway(PaymentMethod method, BigDecimal amount) {
        String txnId = "TXN-" + UUID.randomUUID().toString()
                .replace("-", "").substring(0, 12).toUpperCase();

        boolean success = ThreadLocalRandom.current().nextInt(100) < GATEWAY_SUCCESS_RATE_PERCENT;
        String status = success ? "APPROVED" : "DECLINED";
        String declineReason = success ? null : "Insufficient funds";
        String responseJson = String.format(
                "{\"transactionId\":\"%s\",\"gateway\":\"SimulatedGatewayV1\","
                        + "\"method\":\"%s\",\"amount\":%.2f,"
                        + "\"status\":\"%s\",\"declineReason\":%s,\"timestamp\":\"%s\"}",
                txnId, method.name(), amount,
                status,
                declineReason == null ? "null" : "\"" + declineReason + "\"",
                LocalDateTime.now());

        return new GatewayResult(txnId, success, declineReason, responseJson);
    }

    // ─── Helpers ────────────────────────────────────────────────────────────────

    private Payment findPaymentById(Long id) {
        return paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found with id: " + id));
    }

    private void validateOrderIsPayable(Order order) {
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new RuntimeException("Cannot process payment for a CANCELLED order.");
        }
        if (order.getStatus() == OrderStatus.COMPLETED) {
            throw new RuntimeException("Order is already COMPLETED and fully paid.");
        }
    }

    private PaymentResponseDTO mapToResponseDTO(Payment payment) {
        PaymentResponseDTO dto = new PaymentResponseDTO();
        dto.setPaymentId(payment.getId());
        dto.setTransactionId(payment.getTransactionId());
        dto.setOrderId(payment.getOrder().getId());
        dto.setOrderNumber(payment.getOrder().getOrderNumber());
        dto.setAmount(payment.getAmount());
        dto.setPaymentMethod(payment.getPaymentMethod());
        dto.setPaymentStatus(payment.getPaymentStatus());
        dto.setGatewayResponse(payment.getGatewayResponse());
        dto.setPaidAt(payment.getPaidAt());
        dto.setCreatedAt(payment.getCreatedAt());
        dto.setSuccess(payment.getPaymentStatus() == PaymentStatus.SUCCESS);
        dto.setMessage(resolveMessage(payment.getPaymentStatus()));
        return dto;
    }

    private String resolveMessage(PaymentStatus status) {
        return switch (status) {
            case SUCCESS -> "Payment processed successfully.";
            case FAILED -> "Payment failed. Please retry or use a different payment method.";
            case REFUNDED -> "Payment has been refunded and order has been cancelled.";
            case PROCESSING -> "Payment is being processed.";
            default -> "Payment is pending.";
        };
    }

    /** Internal value object representing the gateway's response. */
    private record GatewayResult(
            String transactionId,
            boolean success,
            String declineReason,
            String responseJson) {
    }
}
