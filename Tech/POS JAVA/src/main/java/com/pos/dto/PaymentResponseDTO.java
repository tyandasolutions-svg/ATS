package com.pos.dto;

import com.pos.model.PaymentMethod;
import com.pos.model.PaymentStatus;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PaymentResponseDTO {

    private Long paymentId;
    private String transactionId;
    private Long orderId;
    private String orderNumber;
    private BigDecimal amount;
    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private String gatewayResponse;
    private String message;
    private boolean success;
    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
}
