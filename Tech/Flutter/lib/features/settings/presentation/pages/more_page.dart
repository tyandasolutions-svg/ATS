import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_pos/features/customers/presentation/pages/customer_list_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.more)),
      body: ListView(
        children: [
          _buildUserHeader(context),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.store,
            title: AppStrings.storeProfile,
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.people_outline,
            title: 'Pelanggan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerListPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.assessment_outlined,
            title: AppStrings.reports,
            onTap: () {},
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            title: AppStrings.taxSettings,
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.print_outlined,
            title: AppStrings.printerSettings,
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.backup_outlined,
            title: AppStrings.backup,
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.restore_outlined,
            title: AppStrings.restore,
            onTap: () {},
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: '${AppStrings.appName} v${AppStrings.appVersion}',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: AppStrings.logout,
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is AuthAuthenticated ? state.user.name : '-';
        final userRole = state is AuthAuthenticated ? state.user.role : '-';
        return Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRole == 'admin' ? 'Admin' : 'Kasir',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
