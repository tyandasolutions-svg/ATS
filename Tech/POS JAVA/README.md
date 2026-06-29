# POS System — Spring Boot

Aplikasi Point of Sale (POS) berbasis REST API menggunakan **Java 17 + Spring Boot 3.2**.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Spring Boot 3.2 |
| Database | H2 (in-memory) |
| ORM | Spring Data JPA / Hibernate |
| Security | Spring Security + JWT (jjwt 0.12) |
| Validation | Jakarta Bean Validation |
| Build | Maven |

---

## Cara Menjalankan

### Prasyarat
- Java 17+
- Maven 3.8+

### Run
```bash
cd "POS JAVA"
mvn spring-boot:run
```

Server berjalan di: `http://localhost:8080`

H2 Console: `http://localhost:8080/h2-console`  
- JDBC URL: `jdbc:h2:mem:posdb`  
- Username: `sa`  
- Password: _(kosong)_

---

## Default Users

| Username | Password   | Role  |
|----------|------------|-------|
| admin    | admin123   | ADMIN |
| cashier  | cashier123 | USER  |

---

## Autentikasi

Semua endpoint (kecuali `/api/auth/**`) memerlukan JWT Bearer Token.

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```
Response:
```json
{
  "token": "<JWT_TOKEN>",
  "tokenType": "Bearer",
  "username": "admin",
  "role": "ADMIN"
}
```

Gunakan token di header untuk semua request berikutnya:
```
Authorization: Bearer <JWT_TOKEN>
```

### Logout
```http
POST /api/auth/logout
```

### Register User Baru
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "staff1",
  "password": "pass123",
  "email": "staff1@pos.com"
}
```

### Info User Saat Ini
```http
GET /api/auth/me
```

---

## API Endpoints

### Products `/api/products`

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/products` | Daftar semua produk |
| GET | `/api/products?name=xxx` | Cari produk berdasarkan nama |
| GET | `/api/products?category=xxx` | Filter berdasarkan kategori |
| GET | `/api/products/{id}` | Detail produk |
| POST | `/api/products` | Tambah produk baru |
| PUT | `/api/products/{id}` | Update produk |
| DELETE | `/api/products/{id}` | Hapus produk |
| GET | `/api/products/low-stock?threshold=10` | Produk dengan stok rendah |
| PATCH | `/api/products/{id}/stock?quantity=5` | Update stok (positif = tambah, negatif = kurang) |

**Body POST/PUT:**
```json
{
  "name": "Laptop Dell XPS",
  "description": "Ultrabook performa tinggi",
  "price": 15000000,
  "stock": 50,
  "category": "Electronics"
}
```

---

### Customers `/api/customers`

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/customers` | Daftar semua pelanggan |
| GET | `/api/customers?name=xxx` | Cari pelanggan |
| GET | `/api/customers/{id}` | Detail pelanggan |
| POST | `/api/customers` | Tambah pelanggan |
| PUT | `/api/customers/{id}` | Update pelanggan |
| DELETE | `/api/customers/{id}` | Hapus pelanggan |

**Body POST/PUT:**
```json
{
  "name": "Budi Santoso",
  "email": "budi@example.com",
  "phone": "081234567890",
  "address": "Jl. Sudirman No. 1, Jakarta"
}
```

---

### Orders `/api/orders`

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/orders` | Daftar semua order |
| GET | `/api/orders?status=PENDING` | Filter berdasarkan status |
| GET | `/api/orders/{id}` | Detail order |
| GET | `/api/orders/number/{orderNumber}` | Cari berdasarkan nomor order |
| GET | `/api/orders/customer/{customerId}` | Order milik pelanggan |
| POST | `/api/orders` | Buat order baru |
| PATCH | `/api/orders/{id}/status?status=CONFIRMED` | Update status order |
| DELETE | `/api/orders/{id}` | Hapus order |

**Status Order:** `PENDING` → `CONFIRMED` → `COMPLETED` / `CANCELLED`

**Body POST:**
```json
{
  "customerId": 1,
  "orderItems": [
    { "productId": 1, "quantity": 2 },
    { "productId": 2, "quantity": 1 }
  ]
}
```

> Saat order dibuat, stok produk **berkurang otomatis**.  
> Saat order di-`CANCEL`, stok produk **dikembalikan otomatis**.

---

## Struktur Project

```
src/main/java/com/pos/
├── PosApplication.java
├── config/
│   ├── SecurityConfig.java       # Konfigurasi Spring Security + JWT
│   └── DataInitializer.java      # Inisialisasi data awal
├── controller/
│   ├── AuthController.java
│   ├── ProductController.java
│   ├── CustomerController.java
│   └── OrderController.java
├── dto/
│   ├── ProductDTO.java
│   ├── CustomerDTO.java
│   ├── OrderRequestDTO.java
│   ├── OrderItemDTO.java
│   ├── LoginRequest.java
│   ├── RegisterRequest.java
│   └── AuthResponse.java
├── exception/
│   └── GlobalExceptionHandler.java
├── model/
│   ├── Product.java
│   ├── Customer.java
│   ├── Order.java
│   ├── OrderItem.java
│   ├── OrderStatus.java
│   └── User.java
├── repository/
│   ├── ProductRepository.java
│   ├── CustomerRepository.java
│   ├── OrderRepository.java
│   └── UserRepository.java
├── security/
│   ├── JwtTokenProvider.java
│   ├── JwtAuthenticationFilter.java
│   └── JwtAuthEntryPoint.java
└── service/
    ├── ProductService.java
    ├── CustomerService.java
    ├── OrderService.java
    └── UserDetailsServiceImpl.java
```
