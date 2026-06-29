package com.pos.controller;

import com.pos.dto.PaymentRequestDTO;
import com.pos.dto.PaymentResponseDTO;
import com.pos.model.PaymentStatus;
import com.pos.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    /** GET /api/payments                   - all payments
     *  GET /api/payments?status=SUCCESS    - filter by status */
    @GetMapping
    public ResponseEntity<List<PaymentResponseDTO>> getAllPayments(
            @RequestParam(required = false) String status) {

        if (status != null && !status.isBlank()) {
            try {
                PaymentStatus paymentStatus = PaymentStatus.valueOf(status.toUpperCase());
                return ResponseEntity.ok(paymentService.getPaymentsByStatus(paymentStatus));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid status: " + status +
                        ". Valid values: PENDING, PROCESSING, SUCCESS, FAILED, REFUNDED");
            }
        }
        return ResponseEntity.ok(paymentService.getAllPayments());
    }

    /** GET /api/payments/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<PaymentResponseDTO> getPaymentById(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getPaymentById(id));
    }

    /** GET /api/payments/order/{orderId}  - all payment attempts for an order */
    @GetMapping("/order/{orderId}")
    public ResponseEntity<List<PaymentResponseDTO>> getPaymentsByOrder(@PathVariable Long orderId) {
        return ResponseEntity.ok(paymentService.getPaymentsByOrderId(orderId));
    }

    /**
     * POST /api/payments
     * <p>
     * Processes a payment for the specified order through the simulated gateway.
     * On success the order status automatically changes to CONFIRMED.
     */
    @PostMapping
    public ResponseEntity<PaymentResponseDTO> processPayment(
            @Valid @RequestBody PaymentRequestDTO requestDTO) {
        PaymentResponseDTO response = paymentService.processPayment(requestDTO);
        HttpStatus status = response.isSuccess() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(response);
    }

    /**
     * POST /api/payments/{id}/refund
     * <p>
     * Refunds a SUCCESS payment and cancels the associated order
     * (product stock is restored automatically).
     */
    @PostMapping("/{id}/refund")
    public ResponseEntity<PaymentResponseDTO> refundPayment(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.refundPayment(id));
    }
}
