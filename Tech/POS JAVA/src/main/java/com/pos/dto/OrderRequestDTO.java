package com.pos.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

@Data
public class OrderRequestDTO {

    private Long customerId;

    @Valid
    @NotEmpty(message = "Order must have at least one item")
    private List<OrderItemDTO> orderItems;
}
