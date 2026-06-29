import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/widgets/app_snackbar.dart';
import 'package:flutter_pos/features/auth/presentation/cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String _enteredPin = '';

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });
      if (_enteredPin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  void _submitPin() {
    if (_enteredPin.length == 6) {
      context.read<AuthCubit>().loginWithPin(_enteredPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppSnackbar.showError(context, state.message);
          _onClear();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSizes.xxl),
                  _buildPinDots(),
                  const SizedBox(height: AppSizes.xl),
                  _buildNumpad(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: const Icon(
            Icons.point_of_sale,
            size: AppSizes.iconXl,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Masukkan PIN untuk login',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _enteredPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: isFilled ? 18 : 14,
              height: isFilled ? 18 : 14,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.textHint
                    : isFilled
                        ? AppColors.primary
                        : Colors.transparent,
                border: Border.all(
                  color: isLoading ? AppColors.textHint : AppColors.primary,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNumpad() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            children: [
              for (var row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['C', '0', '⌫'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((key) {
                      return _NumpadButton(
                        label: key,
                        isDisabled: isLoading,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (key == 'C') {
                            _onClear();
                          } else if (key == '⌫') {
                            _onBackspace();
                          } else {
                            _onNumberTap(key);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  const _NumpadButton({
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSpecial = label == 'C' || label == '⌫';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSpecial
                ? AppColors.background
                : Colors.transparent,
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSpecial ? 18 : 24,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? AppColors.disabled
                  : isSpecial
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
