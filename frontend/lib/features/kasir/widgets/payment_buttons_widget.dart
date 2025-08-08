import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import './manual_payment_dialog.dart';

class PaymentButtonsWidget extends ConsumerWidget {
  final List<Map<String, dynamic>> cart;
  final int totalHarga;
  final VoidCallback onCashPayment;
  final VoidCallback onDigitalPayment;
  final Function(String paymentType) onManualPayment;

  const PaymentButtonsWidget({
    super.key,
    required this.cart,
    required this.totalHarga,
    required this.onCashPayment,
    required this.onDigitalPayment,
    required this.onManualPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Payment Methods
        ...ref
            .watch(AppProviders.availablePaymentMethodsProvider)
            .map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: _buildPaymentButton(context, ref, method),
          );
        }),

        // Platform Info (Debug Mode)
        if (kDebugMode) ...[
          const ResponsiveSpacing(mobileSize: AppTheme.spaceSM),
          Consumer(
            builder: (context, ref, child) {
              final platformInfo = ref.watch(AppProviders.platformInfoProvider);
              return Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  'Platform: ${platformInfo['platform']} | '
                  'Digital Payment: ${platformInfo['digitalPaymentSupported'] ? '✓' : '✗'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentButton(
      BuildContext context, WidgetRef ref, AppProviders.PaymentMethod method) {
    switch (method) {
      case AppProviders.PaymentMethod.manual:
        return FilledButton.tonal(
          onPressed: cart.isEmpty
              ? null
              : () => ManualPaymentDialog.show(
                    context,
                    totalHarga: totalHarga,
                    onManualPaymentSelected: onManualPayment,
                    onDigitalPaymentInitiated:
                        () {}, // Kosongkan karena tidak digunakan
                  ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_send),
              SizedBox(width: AppTheme.spaceSM),
              Text('Pembayaran Manual'),
            ],
          ),
        );
      case AppProviders.PaymentMethod.cash:
        final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);
        return FilledButton.icon(
          onPressed: cart.isEmpty ? null : onCashPayment,
          icon: Icon(isOfflineMode ? Icons.offline_bolt : Icons.payments),
          label: const Text('Pembayaran Tunai'),
          style: FilledButton.styleFrom(
            backgroundColor: isOfflineMode
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
            foregroundColor: isOfflineMode
                ? Theme.of(context).colorScheme.onTertiary
                : Theme.of(context).colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
