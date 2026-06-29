import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 [${options.method}] ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '✅ [${response.statusCode}] ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '❌ [${err.response?.statusCode}] ${err.requestOptions.uri}',
    );

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(
          message: 'Koneksi timeout, coba lagi nanti',
        );
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        _handleBadResponse(err.response!);
      default:
        throw ServerException(
          message: err.message ?? 'Terjadi kesalahan pada server',
        );
    }

    handler.next(err);
  }

  void _handleBadResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;
    final message = data is Map ? data['message'] as String? : null;

    switch (statusCode) {
      case 401:
        throw AuthException(
          message: message ?? 'Sesi telah berakhir',
        );
      case 403:
        throw AuthException(
          message: message ?? 'Akses ditolak',
        );
      case 404:
        throw ServerException(
          message: message ?? 'Data tidak ditemukan',
          statusCode: 404,
        );
      case 422:
        throw ValidationException(
          message: message ?? 'Data tidak valid',
        );
      default:
        throw ServerException(
          message: message ?? 'Terjadi kesalahan pada server',
          statusCode: statusCode,
        );
    }
  }
}
