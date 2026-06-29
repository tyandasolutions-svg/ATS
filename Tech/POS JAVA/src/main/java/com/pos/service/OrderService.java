package com.pos.service;

import com.pos.dto.OrderItemDTO;
import com.pos.dto.OrderRequestDTO;
import com.pos.model.*;
import com.pos.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Service
@Transactional
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductService productService;

    @Autowired
    private CustomerService customerService;

    @Transactional(readOnly = true)
    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Order getOrderById(Long id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
    }

    @Transactional(readOnly = true)
    public Order getOrderByNumber(String orderNumber) {
        return orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found with number: " + orderNumber));
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByCustomer(Long customerId) {
        return orderRepository.findByCustomerId(customerId);
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status);
    }

    public Order createOrder(OrderRequestDTO orderRequestDTO) {
        Order order = new Order();
        order.setOrderNumber(generateOrderNumber());
        order.setStatus(OrderStatus.PENDING);

        // Assign customer if provided
        if (orderRequestDTO.getCustomerId() != null) {
            Customer customer = customerService.getCustomerById(orderRequestDTO.getCustomerId());
            order.setCustomer(customer);
        }

        BigDecimal totalAmount = BigDecimal.ZERO;

        for (OrderItemDTO itemDTO : orderRequestDTO.getOrderItems()) {
            Product product = productService.getProductById(itemDTO.getProductId());

            // Validate stock availability
            if (product.getStock() < itemDTO.getQuantity()) {
                throw new RuntimeException(
                        "Insufficient stock for product '" + product.getName() +
                        "'. Available: " + product.getStock() +
                        ", Requested: " + itemDTO.getQuantity());
            }

            BigDecimal subtotal = product.getPrice().multiply(BigDecimal.valueOf(itemDTO.getQuantity()));

            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            orderItem.setProduct(product);
            orderItem.setQuantity(itemDTO.getQuantity());
            orderItem.setUnitPrice(product.getPrice());
            orderItem.setSubtotal(subtotal);

            order.getOrderItems().add(orderItem);
            totalAmount = totalAmount.add(subtotal);

            // Deduct stock automatically
            productService.updateStock(product.getId(), -itemDTO.getQuantity());
        }

        order.setTotalAmount(totalAmount);
        return orderRepository.save(order);
    }

    public Order updateOrderStatus(Long id, OrderStatus newStatus) {
        Order order = getOrderById(id);
        OrderStatus currentStatus = order.getStatus();

        // Restore stock when an active order is cancelled
        if (newStatus == OrderStatus.CANCELLED && currentStatus != OrderStatus.CANCELLED) {
            for (OrderItem item : order.getOrderItems()) {
                productService.updateStock(item.getProduct().getId(), item.getQuantity());
            }
        }

        order.setStatus(newStatus);
        return orderRepository.save(order);
    }

    public void deleteOrder(Long id) {
        Order order = getOrderById(id);
        // Restore stock only if order was still active (not completed/cancelled)
        if (order.getStatus() != OrderStatus.COMPLETED && order.getStatus() != OrderStatus.CANCELLED) {
            for (OrderItem item : order.getOrderItems()) {
                productService.updateStock(item.getProduct().getId(), item.getQuantity());
            }
        }
        orderRepository.delete(order);
    }

    private String generateOrderNumber() {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        int random = ThreadLocalRandom.current().nextInt(100, 999);
        return "ORD-" + timestamp + "-" + random;
    }
}
