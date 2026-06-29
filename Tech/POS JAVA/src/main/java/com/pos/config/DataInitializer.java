package com.pos.config;

import com.pos.model.Customer;
import com.pos.model.Product;
import com.pos.model.User;
import com.pos.repository.CustomerRepository;
import com.pos.repository.ProductRepository;
import com.pos.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializer.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        initUsers();
        initProducts();
        initCustomers();
        logger.info("=== POS System data initialization complete ===");
    }

    private void initUsers() {
        if (!userRepository.existsByUsername("admin")) {
            User admin = new User();
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setEmail("admin@pos.com");
            admin.setRole("ADMIN");
            admin.setEnabled(true);
            userRepository.save(admin);
            logger.info("Created default admin user  (username: admin / password: admin123)");
        }

        if (!userRepository.existsByUsername("cashier")) {
            User cashier = new User();
            cashier.setUsername("cashier");
            cashier.setPassword(passwordEncoder.encode("cashier123"));
            cashier.setEmail("cashier@pos.com");
            cashier.setRole("USER");
            cashier.setEnabled(true);
            userRepository.save(cashier);
            logger.info("Created default cashier user (username: cashier / password: cashier123)");
        }
    }

    private void initProducts() {
        if (productRepository.count() == 0) {
            productRepository.save(buildProduct("Laptop Dell XPS 13",
                    "High-performance ultrabook", new BigDecimal("15000000"), 50, "Electronics"));
            productRepository.save(buildProduct("Mouse Wireless Logitech",
                    "Wireless optical mouse", new BigDecimal("250000"), 100, "Electronics"));
            productRepository.save(buildProduct("Keyboard Mechanical",
                    "Mechanical gaming keyboard", new BigDecimal("800000"), 75, "Electronics"));
            productRepository.save(buildProduct("Monitor 24 Inch Full HD",
                    "IPS Full HD display", new BigDecimal("3500000"), 30, "Electronics"));
            productRepository.save(buildProduct("USB Hub 4-Port",
                    "USB 3.0 hub", new BigDecimal("150000"), 200, "Accessories"));
            productRepository.save(buildProduct("Headset Gaming",
                    "Stereo gaming headset with mic", new BigDecimal("450000"), 60, "Electronics"));
            productRepository.save(buildProduct("Webcam HD 1080p",
                    "Full HD webcam for video calls", new BigDecimal("350000"), 80, "Accessories"));
            logger.info("Inserted {} sample products", productRepository.count());
        }
    }

    private void initCustomers() {
        if (customerRepository.count() == 0) {
            customerRepository.save(buildCustomer("Budi Santoso",
                    "budi@example.com", "081234567890", "Jl. Sudirman No. 1, Jakarta"));
            customerRepository.save(buildCustomer("Siti Rahayu",
                    "siti@example.com", "082345678901", "Jl. Thamrin No. 5, Jakarta"));
            customerRepository.save(buildCustomer("Ahmad Yusuf",
                    "ahmad@example.com", "083456789012", "Jl. Gatot Subroto No. 10, Bandung"));
            logger.info("Inserted {} sample customers", customerRepository.count());
        }
    }

    private Product buildProduct(String name, String desc, BigDecimal price, int stock, String category) {
        Product p = new Product();
        p.setName(name);
        p.setDescription(desc);
        p.setPrice(price);
        p.setStock(stock);
        p.setCategory(category);
        return p;
    }

    private Customer buildCustomer(String name, String email, String phone, String address) {
        Customer c = new Customer();
        c.setName(name);
        c.setEmail(email);
        c.setPhone(phone);
        c.setAddress(address);
        return c;
    }
}
