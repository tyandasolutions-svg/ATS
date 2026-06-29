package com.pos.service;

import com.pos.dto.ProductDTO;
import com.pos.model.Product;
import com.pos.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ProductService Unit Tests")
class ProductServiceTest {

    @InjectMocks
    private ProductService productService;

    @Mock
    private ProductRepository productRepository;

    private Product sampleProduct;

    @BeforeEach
    void setUp() {
        sampleProduct = new Product();
        sampleProduct.setId(1L);
        sampleProduct.setName("Laptop Dell XPS");
        sampleProduct.setDescription("High-performance laptop");
        sampleProduct.setPrice(new BigDecimal("15000000"));
        sampleProduct.setStock(50);
        sampleProduct.setCategory("Electronics");
    }

    // ─── getAllProducts ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("getAllProducts returns all products from repository")
    void getAllProducts_ReturnsAllProducts() {
        when(productRepository.findAll()).thenReturn(List.of(sampleProduct));

        List<Product> result = productService.getAllProducts();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Laptop Dell XPS");
        verify(productRepository, times(1)).findAll();
    }

    // ─── getProductById ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("getProductById returns product when ID exists")
    void getProductById_WhenExists_ReturnsProduct() {
        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));

        Product result = productService.getProductById(1L);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getName()).isEqualTo("Laptop Dell XPS");
    }

    @Test
    @DisplayName("getProductById throws RuntimeException when product not found")
    void getProductById_WhenNotFound_ThrowsRuntimeException() {
        when(productRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> productService.getProductById(99L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Product not found with id: 99");
    }

    // ─── createProduct ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("createProduct saves and returns a new product")
    void createProduct_WithValidDTO_ReturnsCreatedProduct() {
        ProductDTO dto = new ProductDTO();
        dto.setName("Mouse Wireless");
        dto.setPrice(new BigDecimal("250000"));
        dto.setStock(100);
        dto.setCategory("Electronics");

        when(productRepository.save(any(Product.class))).thenReturn(sampleProduct);

        Product result = productService.createProduct(dto);

        assertThat(result).isNotNull();
        verify(productRepository, times(1)).save(any(Product.class));
    }

    // ─── updateProduct ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("updateProduct updates and returns the product when ID exists")
    void updateProduct_WhenExists_ReturnsUpdatedProduct() {
        ProductDTO dto = new ProductDTO();
        dto.setName("Laptop Dell XPS 15");
        dto.setPrice(new BigDecimal("18000000"));
        dto.setStock(40);
        dto.setCategory("Electronics");

        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));
        when(productRepository.save(any(Product.class))).thenReturn(sampleProduct);

        Product result = productService.updateProduct(1L, dto);

        assertThat(result).isNotNull();
        verify(productRepository, times(1)).findById(1L);
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    @DisplayName("updateProduct throws RuntimeException when product not found")
    void updateProduct_WhenNotFound_ThrowsRuntimeException() {
        when(productRepository.findById(99L)).thenReturn(Optional.empty());

        ProductDTO dto = new ProductDTO();
        dto.setName("Ghost Product");
        dto.setPrice(BigDecimal.ONE);
        dto.setStock(1);

        assertThatThrownBy(() -> productService.updateProduct(99L, dto))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Product not found with id: 99");
    }

    // ─── deleteProduct ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("deleteProduct deletes the product when ID exists")
    void deleteProduct_WhenExists_DeletesSuccessfully() {
        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));
        doNothing().when(productRepository).delete(sampleProduct);

        assertThatCode(() -> productService.deleteProduct(1L)).doesNotThrowAnyException();
        verify(productRepository, times(1)).delete(sampleProduct);
    }

    // ─── updateStock ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("updateStock increases stock correctly")
    void updateStock_WithPositiveDelta_IncreasesStock() {
        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArguments()[0]);

        Product result = productService.updateStock(1L, 10);

        assertThat(result.getStock()).isEqualTo(60);
    }

    @Test
    @DisplayName("updateStock decreases stock correctly when sufficient")
    void updateStock_WithNegativeDelta_DecreasesStock() {
        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArguments()[0]);

        Product result = productService.updateStock(1L, -10);

        assertThat(result.getStock()).isEqualTo(40);
    }

    @Test
    @DisplayName("updateStock throws RuntimeException when stock would go negative")
    void updateStock_WhenInsufficientStock_ThrowsRuntimeException() {
        when(productRepository.findById(1L)).thenReturn(Optional.of(sampleProduct));

        // Attempt to reduce by more than available (stock = 50)
        assertThatThrownBy(() -> productService.updateStock(1L, -100))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Insufficient stock");
    }

    // ─── searchProductsByName ────────────────────────────────────────────────────

    @Test
    @DisplayName("searchProductsByName delegates to repository")
    void searchProductsByName_ReturnsList() {
        when(productRepository.findByNameContainingIgnoreCase("laptop"))
                .thenReturn(List.of(sampleProduct));

        List<Product> result = productService.searchProductsByName("laptop");

        assertThat(result).hasSize(1);
        verify(productRepository).findByNameContainingIgnoreCase("laptop");
    }

    // ─── getLowStockProducts ─────────────────────────────────────────────────────

    @Test
    @DisplayName("getLowStockProducts returns products below threshold")
    void getLowStockProducts_ReturnsBelowThreshold() {
        Product lowStockProduct = new Product();
        lowStockProduct.setId(2L);
        lowStockProduct.setStock(5);

        when(productRepository.findByStockLessThan(10)).thenReturn(List.of(lowStockProduct));

        List<Product> result = productService.getLowStockProducts(10);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getStock()).isLessThan(10);
    }
}
