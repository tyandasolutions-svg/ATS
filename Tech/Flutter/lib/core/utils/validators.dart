abstract final class Validators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field'} wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN wajib diisi';
    }
    if (value.length != 6) {
      return 'PIN harus 6 digit';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN harus berupa angka';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga wajib diisi';
    }
    final cleaned = value.replaceAll('.', '').replaceAll(',', '');
    final price = num.tryParse(cleaned);
    if (price == null || price < 0) {
      return 'Harga tidak valid';
    }
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stok wajib diisi';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'Stok tidak valid';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'Field'} minimal $min karakter';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'Field'} maksimal $max karakter';
    }
    return null;
  }

  static String? numeric(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) return null;
    if (num.tryParse(value) == null) {
      return '${fieldName ?? 'Field'} harus berupa angka';
    }
    return null;
  }
}
