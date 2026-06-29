package com.pos.service;

import com.pos.dto.OrderItemDTO;
import com.pos.dto.OrderRequestDTO;
import com.pos.model.*;
import com.pos.repository.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderService Unit Tests")
class OrderServiceTest {

    @InjectMocks
    private OrderService orderService;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ProductService productService;

    @Mock
    private CustomerService customerService;

    private Product sampleProduct;
    private Order sampleOrder;

    @BeforeEach
    void setUp() {
        sampleProduct = new Product();
        sampleProduct.setId(1L);
        sampleProduct.setName("Laptop Dell XPS");
        sampleProduct.setPrice(new BigDecimal("15000000"));
        sampleProduct.setStock(20);

        sampleOrder = new Order();
        sampleOrder.setId(1L);
        sampleOrder.setOrderNumber("ORD-20260629120000-123");
        sampleOrder.setStatus(OrderStatus.PENDING);
        sampleOrder.setTotalAmount(new BigDecimal("30000000"));
        sampleOrder.setOrderItems(new ArrayList<>());
    }

    // ─── getAllOrders ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("getAllOrders returns all orders from repository")
    void getAllOrders_ReturnsList() {
        when(orderRepository.findAll()).thenReturn(List.of(sampleOrder));

        List<Order> result = orderService.getAllOrders();

        assertThat(result).hasSize(1);
        verify(orderRepository, times(1)).findAll();
    }

    // ─── getOrderById ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("getOrderById returns order when ID exists")
    void getOrderById_WhenExists_ReturnsOrder() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(sampleOrder));

        Order result = orderService.getOrderById(1L);

        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getStatus()).isEqualTo(OrderStatus.PENDING);
    }

    @Test
    @DisplayName("getOrderById throws when order not found")
    void getOrderById_WhenNotFound_ThrowsRuntimeException() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.getOrderById(99L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Order not found with id: 99");
    }

    // ─── createOrder ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("createOrder saves order and deducts product stock")
    void createOrder_WithSufficientStock_CreatesOrderAndDeductsStock() {
        OrderItemDTO itemDTO = new OrderItemDTO();
        itemDTO.setProductId(1L);
        itemDTO.setQuantity(2);

        OrderRequestDTO requestDTO = new OrderRequestDTO();
        requestDTO.setOrderItems(List.of(itemDTO));

        when(productService.getProductById(1L)).thenReturn(sampleProduct);
        when(productService.updateStock(eq(1L), eq(-2))).thenReturn(sampleProduct);
        when(orderRepository.save(any(Order.class))).thenReturn(sampleOrder);

        Order result = orderService.createOrder(requestDTO);

        assertThat(result).isNotNull();
        verify(productService, times(1)).updateStock(eq(1L), eq(-2));
        verify(orderRepository, times(1)).save(any(Order.class));
    }

    @Test
    @DisplayName("createOrder throws when stock is insufficient")
    void createOrder_WhenInsufficientStock_ThrowsRuntimeException() {
        // Product has stock = 20, but request asks for 100
        OrderItemDTO itemDTO = new OrderItemDTO();
        itemDTO.setProductId(1L);
        itemDTO.setQuantity(100);

        OrderRequestDTO requestDTO = new OrderRequestDTO();
        requestDTO.setOrderItems(List.of(itemDTO));

        when(productService.getProductById(1L)).thenReturn(sampleProduct);

        assertThatThrownBy(() -> orderService.createOrder(requestDTO))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Insufficient stock");
    }

    @Test
    @DisplayName("createOrder assigns customer when customerId is provided")
    void createOrder_WithCustomerId_AssignsCustomer() {
        Customer customer = new Customer();
        customer.setId(5L);
        customer.setName("Budi");

        OrderItemDTO itemDTO = new OrderItemDTO();
        itemDTO.setProductId(1L);
        itemDTO.setQuantity(1);

        OrderRequestDTO requestDTO = new OrderRequestDTO();
        requestDTO.setCustomerId(5L);
        requestDTO.setOrderItems(List.of(itemDTO));

        when(customerService.getCustomerById(5L)).thenReturn(customer);
        when(productService.getProductById(1L)).thenReturn(sampleProduct);
        when(productService.updateStock(eq(1L), eq(-1))).thenReturn(sampleProduct);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> {
            Order o = invocation.getArgument(0);
            o.setId(1L);
            return o;
        });

        Order result = orderService.createOrder(requestDTO);

        assertThat(result.getCustomer()).isNotNull();
        assertThat(result.getCustomer().getName()).isEqualTo("Budi");
    }

    // ─── updateOrderStatus ───────────────────────────────────────────────────────

    @Test
    @DisplayName("updateOrderStatus changes order status correctly")
    void updateOrderStatus_ChangesStatusToConfirmed() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(sampleOrder));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArguments()[0]);

        Order result = orderService.updateOrderStatus(1L, OrderStatus.CONFIRMED);

        assertThat(result.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
    }

    @Test
    @DisplayName("updateOrderStatus to CANCELLED restores product stock")
    void updateOrderStatus_WhenCancelled_RestoresStock() {
        // Prepare an order with an item
        OrderItem item = new OrderItem();
        item.setProduct(sampleProduct);
        item.setQuantity(3);
        item.setUnitPrice(sampleProduct.getPrice());
        item.setSubtotal(sampleProduct.getPrice().multiply(BigDecimal.valueOf(3)));
        sampleOrder.getOrderItems().add(item);

        when(orderRepository.findById(1L)).thenReturn(Optional.of(sampleOrder));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArguments()[0]);

        orderService.updateOrderStatus(1L, OrderStatus.CANCELLED);

        // Stock should be restored (+3)
        verify(productService, times(1)).updateStock(eq(1L), eq(3));
    }

    @Test
    @DisplayName("updateOrderStatus to CANCELLED when already CANCELLED does not restore stock twice")
    void updateOrderStatus_WhenAlreadyCancelled_DoesNotRestoreStock() {
        sampleOrder.setStatus(OrderStatus.CANCELLED);

        OrderItem item = new OrderItem();
        item.setProduct(sampleProduct);
        item.setQuantity(2);
        sampleOrder.getOrderItems().add(item);

        when(orderRepository.findById(1L)).thenReturn(Optional.of(sampleOrder));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArguments()[0]);

        orderService.updateOrderStatus(1L, OrderStatus.CANCELLED);

        // Already CANCELLED → no stock restoration
        verify(productService, never()).updateStock(any(), any());
    }

    // ─── getOrdersByCustomer ─────────────────────────────────────────────────────

    @Test
    @DisplayName("getOrdersByCustomer delegates to repository")
    void getOrdersByCustomer_ReturnsList() {
        when(orderRepository.findByCustomerId(1L)).thenReturn(List.of(sampleOrder));

        List<Order> result = orderService.getOrdersByCustomer(1L);

        assertThat(result).hasSize(1);
    }

    // ─── getOrdersByStatus ───────────────────────────────────────────────────────

    @Test
    @DisplayName("getOrdersByStatus filters correctly")
    void getOrdersByStatus_ReturnsPendingOrders() {
        when(orderRepository.findByStatus(OrderStatus.PENDING)).thenReturn(List.of(sampleOrder));

        List<Order> result = orderService.getOrdersByStatus(OrderStatus.PENDING);

        assertThat(result).allMatch(o -> o.getStatus() == OrderStatus.PENDING);
    }
}
