class CurrencyFormatter {
  /// Format mata uang Rupiah dengan pemisah ribuan
  static String formatCurrency(dynamic amount) {
    // Handle null and different number types
    double value = 0.0;

    if (amount == null) {
      value = 0.0;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else {
      value = 0.0;
    }

    int intValue = value.round();

    return 'Rp ${intValue.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}
