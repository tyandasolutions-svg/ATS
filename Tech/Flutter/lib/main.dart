import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/di/injection.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_pos/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_pos/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter_pos/features/home/presentation/pages/main_navigation_page.dart';
import 'package:flutter_pos/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_pos/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:flutter_pos/features/reports/presentation/cubit/dashboard_cubit.dart';
import 'package:flutter_pos/features/customers/presentation/pages/customer_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local cache
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);

  // Setup dependency injection
  await configureDependencies();

  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (_) => getIt<ProductCubit>()),
        BlocProvider(create: (_) => getIt<CartCubit>()),
        BlocProvider(create: (_) => getIt<TransactionCubit>()),
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<CustomerCubit>()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return MainNavigationPage(
                userName: state.user.name,
                userRole: state.user.role,
              );
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
