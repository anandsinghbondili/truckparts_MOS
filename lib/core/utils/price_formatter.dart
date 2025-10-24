class PriceFormatter {
  /// Formats a price with comma separators for thousands and decimal places
  /// Example: 1234567.89 -> "12,34,567.89", 1234567 -> "12,34,567.00"
  /// Always shows 2 decimal places for consistency
  static String formatPrice(double? price) {
    if (price == null) return 'N/A';

    // Format to exactly 2 decimal places
    final formattedPrice = price.toStringAsFixed(2);

    // Split into integer and decimal parts
    final parts = formattedPrice.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas to integer part
    final formattedInteger = _addCommas(integerPart);

    // Always include decimal part with exactly 2 digits
    return '$formattedInteger.$decimalPart';
  }

  /// Adds commas to a number string for thousands separators (Indian format)
  /// Example: "1234567" -> "12,34,567"
  static String _addCommas(String number) {
    if (number.length <= 3) return number;

    final reversed = number.split('').reversed.join('');
    final parts = <String>[];

    // First group: 3 digits from right
    if (reversed.length >= 3) {
      parts.add(reversed.substring(0, 3));
    } else {
      parts.add(reversed);
      // Reverse the part back to normal and return
      return parts[0].split('').reversed.join('');
    }

    // Remaining groups: 2 digits each
    for (int i = 3; i < reversed.length; i += 2) {
      if (i + 2 <= reversed.length) {
        parts.add(reversed.substring(i, i + 2));
      } else {
        parts.add(reversed.substring(i));
      }
    }

    // Reverse each part back to normal, then reverse the array order and join
    final result = parts.reversed
        .map((part) => part.split('').reversed.join(''))
        .join(',');

    // Remove leading zeros but keep at least one digit
    final cleanedResult = result.replaceFirst(RegExp(r'^0+'), '');
    return cleanedResult.isEmpty ? '0' : cleanedResult;
  }

  /// Formats a price with currency symbol and comma separators
  /// Example: 1234567.89 -> "₹12,34,567.89"
  static String formatPriceWithCurrency(double? price) {
    return '₹${formatPrice(price)}';
  }
}
