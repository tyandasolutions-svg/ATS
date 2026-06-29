package com.pos.service;

import com.pos.dto.CustomerDTO;
import com.pos.model.Customer;
import com.pos.repository.CustomerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("CustomerService Unit Tests")
class CustomerServiceTest {

    @InjectMocks
    private CustomerService customerService;

    @Mock
    private CustomerRepository customerRepository;

    private Customer sampleCustomer;

    @BeforeEach
    void setUp() {
        sampleCustomer = new Customer();
        sampleCustomer.setId(1L);
        sampleCustomer.setName("Budi Santoso");
        sampleCustomer.setEmail("budi@example.com");
        sampleCustomer.setPhone("081234567890");
        sampleCustomer.setAddress("Jl. Sudirman No. 1, Jakarta");
    }

    // ─── getAllCustomers ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("getAllCustomers returns full list from repository")
    void getAllCustomers_ReturnsList() {
        when(customerRepository.findAll()).thenReturn(List.of(sampleCustomer));

        List<Customer> result = customerService.getAllCustomers();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Budi Santoso");
        verify(customerRepository, times(1)).findAll();
    }

    // ─── getCustomerById ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("getCustomerById returns customer when ID exists")
    void getCustomerById_WhenExists_ReturnsCustomer() {
        when(customerRepository.findById(1L)).thenReturn(Optional.of(sampleCustomer));

        Customer result = customerService.getCustomerById(1L);

        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getEmail()).isEqualTo("budi@example.com");
    }

    @Test
    @DisplayName("getCustomerById throws when customer not found")
    void getCustomerById_WhenNotFound_ThrowsRuntimeException() {
        when(customerRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> customerService.getCustomerById(99L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Customer not found with id: 99");
    }

    // ─── createCustomer ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("createCustomer saves and returns new customer")
    void createCustomer_WithValidDTO_ReturnsCreatedCustomer() {
        CustomerDTO dto = new CustomerDTO();
        dto.setName("Siti Rahayu");
        dto.setEmail("siti@example.com");
        dto.setPhone("082345678901");

        when(customerRepository.findByEmail("siti@example.com")).thenReturn(Optional.empty());
        when(customerRepository.save(any(Customer.class))).thenReturn(sampleCustomer);

        Customer result = customerService.createCustomer(dto);

        assertThat(result).isNotNull();
        verify(customerRepository).save(any(Customer.class));
    }

    @Test
    @DisplayName("createCustomer throws when email already exists")
    void createCustomer_WhenEmailExists_ThrowsRuntimeException() {
        CustomerDTO dto = new CustomerDTO();
        dto.setName("Duplicate User");
        dto.setEmail("budi@example.com");

        when(customerRepository.findByEmail("budi@example.com"))
                .thenReturn(Optional.of(sampleCustomer));

        assertThatThrownBy(() -> customerService.createCustomer(dto))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Customer with email already exists");
    }

    // ─── updateCustomer ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("updateCustomer updates fields and returns updated customer")
    void updateCustomer_WhenExists_ReturnsUpdatedCustomer() {
        CustomerDTO dto = new CustomerDTO();
        dto.setName("Budi Santoso Updated");
        dto.setEmail("budi.new@example.com");
        dto.setPhone("081111111111");

        when(customerRepository.findById(1L)).thenReturn(Optional.of(sampleCustomer));
        when(customerRepository.save(any(Customer.class))).thenAnswer(i -> i.getArguments()[0]);

        Customer result = customerService.updateCustomer(1L, dto);

        assertThat(result.getName()).isEqualTo("Budi Santoso Updated");
        assertThat(result.getPhone()).isEqualTo("081111111111");
    }

    // ─── deleteCustomer ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("deleteCustomer deletes the customer without error")
    void deleteCustomer_WhenExists_DeletesSuccessfully() {
        when(customerRepository.findById(1L)).thenReturn(Optional.of(sampleCustomer));
        doNothing().when(customerRepository).delete(sampleCustomer);

        assertThatCode(() -> customerService.deleteCustomer(1L)).doesNotThrowAnyException();
        verify(customerRepository).delete(sampleCustomer);
    }

    // ─── searchCustomersByName ───────────────────────────────────────────────────

    @Test
    @DisplayName("searchCustomersByName delegates to repository")
    void searchCustomersByName_ReturnsList() {
        when(customerRepository.findByNameContainingIgnoreCase("budi"))
                .thenReturn(List.of(sampleCustomer));

        List<Customer> result = customerService.searchCustomersByName("budi");

        assertThat(result).hasSize(1);
        verify(customerRepository).findByNameContainingIgnoreCase("budi");
    }
}
