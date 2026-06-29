import 'package:get_it/get_it.dart';
import 'package:flutter_pos/core/database/app_database.dart';
import 'package:flutter_pos/core/network/api_client.dart';
import 'package:flutter_pos/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_pos/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_pos/features/products/data/datasources/product_local_datasource.dart';
import 'package:flutter_pos/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_pos/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/products/domain/usecases/product_usecases.dart';
import 'package:flutter_pos/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_pos/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter_pos/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:flutter_pos/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_pos/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_pos/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:flutter_pos/features/reports/presentation/cubit/dashboard_cubit.dart';
import 'package:flutter_pos/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:flutter_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:flutter_pos/features/customers/presentation/pages/customer_list_page.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ==================== Core ====================
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: 'https://api.example.com/v1'),
  );

  // ==================== Auth ====================
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: getIt<AuthLocalDataSource>()),
  );
  getIt.registerLazySingleton(
    () => LoginWithPinUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAllUsersUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory(
    () => AuthCubit(
      loginWithPin: getIt<LoginWithPinUseCase>(),
      logout: getIt<LogoutUseCase>(),
      getCurrentUser: getIt<GetCurrentUserUseCase>(),
    ),
  );

  // ==================== Products ====================
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
        localDataSource: getIt<ProductLocalDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetProductsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProductByBarcodeUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<ProductRepository>()),
  );
  getIt.registerFactory(
    () => ProductCubit(
      getProducts: getIt<GetProductsUseCase>(),
      getProductByBarcode: getIt<GetProductByBarcodeUseCase>(),
      createProduct: getIt<CreateProductUseCase>(),
      updateProduct: getIt<UpdateProductUseCase>(),
      deleteProduct: getIt<DeleteProductUseCase>(),
      getCategories: getIt<GetCategoriesUseCase>(),
    ),
  );

  // ==================== Cart ====================
  getIt.registerLazySingleton(() => CartCubit());

  // ==================== Transactions ====================
  getIt.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
        localDataSource: getIt<TransactionLocalDataSource>()),
  );
  getIt.registerFactory(
    () => TransactionCubit(repository: getIt<TransactionRepository>()),
  );

  // ==================== Dashboard ====================
  getIt.registerFactory(
    () => DashboardCubit(repository: getIt<TransactionRepository>()),
  );

  // ==================== Customers ====================
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(getIt<AppDatabase>()),
  );
  getIt.registerFactory(
    () => CustomerCubit(repository: getIt<CustomerRepository>()),
  );
}
