package com.pos.service;

import com.pos.dto.ProductDTO;
import com.pos.model.Product;
import com.pos.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Product getProductById(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
    }

    public Product createProduct(ProductDTO productDTO) {
        Product product = new Product();
        mapDtoToEntity(productDTO, product);
        return productRepository.save(product);
    }

    public Product updateProduct(Long id, ProductDTO productDTO) {
        Product product = getProductById(id);
        mapDtoToEntity(productDTO, product);
        return productRepository.save(product);
    }

    public void deleteProduct(Long id) {
        Product product = getProductById(id);
        productRepository.delete(product);
    }

    @Transactional(readOnly = true)
    public List<Product> searchProductsByName(String name) {
        return productRepository.findByNameContainingIgnoreCase(name);
    }

    @Transactional(readOnly = true)
    public List<Product> getProductsByCategory(String category) {
        return productRepository.findByCategory(category);
    }

    @Transactional(readOnly = true)
    public List<Product> getLowStockProducts(Integer threshold) {
        return productRepository.findByStockLessThan(threshold);
    }

    /**
     * Adjusts stock by the given delta (positive = increase, negative = decrease).
     * Throws RuntimeException if the resulting stock would be negative.
     */
    public Product updateStock(Long id, Integer delta) {
        Product product = getProductById(id);
        int newStock = product.getStock() + delta;
        if (newStock < 0) {
            throw new RuntimeException(
                    "Insufficient stock for product '" + product.getName() +
                    "'. Available: " + product.getStock() + ", Requested reduction: " + Math.abs(delta));
        }
        product.setStock(newStock);
        return productRepository.save(product);
    }

    private void mapDtoToEntity(ProductDTO dto, Product product) {
        product.setName(dto.getName());
        product.setDescription(dto.getDescription());
        product.setPrice(dto.getPrice());
        product.setStock(dto.getStock());
        product.setCategory(dto.getCategory());
    }
}
