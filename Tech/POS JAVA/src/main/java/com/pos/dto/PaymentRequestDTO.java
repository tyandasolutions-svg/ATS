package com.pos.dto;

import com.pos.model.PaymentMethod;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PaymentRequestDTO {

    @NotNull(message = "Order ID is required")
    private Long orderId;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    /** Optional: last 4 digits of card (for display only, never stored in full) */
    private String cardLastFour;

    /** Optional: bank name for bank-transfer payments */
    private String bankName;

    /** Optional: e-wallet provider name */
    private String walletProvider;
}
