class ClassifiedSms {
  final String category; // Personal, Transactions, OTP, Promotions, Bills, Spam
  final String? otpCode;
  final double? amount;
  final String? merchant;
  final DateTime? dueDate;

  ClassifiedSms({
    required this.category,
    this.otpCode,
    this.amount,
    this.merchant,
    this.dueDate,
  });
}

class SmsClassifier {
  static ClassifiedSms classify(String sender, String body) {
    final lowerBody = body.toLowerCase();

    // 1. OTP Detection
    if (lowerBody.contains('otp') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('one-time password') ||
        lowerBody.contains('security code')) {
      final otpRegExp = RegExp(r'\b\d{4,8}\b');
      final match = otpRegExp.firstMatch(body);
      return ClassifiedSms(
        category: 'OTPs',
        otpCode: match?.group(0),
      );
    }

    // 2. Transaction Detection
    if (lowerBody.contains('debited') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('received') ||
        lowerBody.contains('a/c') ||
        lowerBody.contains('upi') ||
        lowerBody.contains('balance')) {

      final amountRegExp = RegExp(r'(?:[$£€₹]|Rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false);
      final match = amountRegExp.firstMatch(body);
      double? amount;
      if (match != null && match.group(1) != null) {
        final cleanAmount = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(cleanAmount);
      }

      return ClassifiedSms(
        category: 'Transactions',
        amount: amount,
        merchant: sender,
      );
    }

    // 3. Bill / Reminder Detection
    if (lowerBody.contains('bill') ||
        lowerBody.contains('due') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('emi') ||
        lowerBody.contains('renewal')) {

      final amountRegExp = RegExp(r'(?:[$£€₹]|Rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false);
      final match = amountRegExp.firstMatch(body);
      double? amount;
      if (match != null && match.group(1) != null) {
        final cleanAmount = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(cleanAmount);
      }

      return ClassifiedSms(
        category: 'Bills',
        amount: amount,
        merchant: sender,
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );
    }

    // 4. Promotion Detection
    if (lowerBody.contains('offer') ||
        lowerBody.contains('discount') ||
        lowerBody.contains('sale') ||
        lowerBody.contains('cashback') ||
        lowerBody.contains('promo') ||
        lowerBody.contains('off') ||
        (sender.length < 6 && sender.contains(RegExp(r'^[A-Z]+$')))) {
      return ClassifiedSms(category: 'Promotions');
    }

    // Default to Personal
    return ClassifiedSms(category: 'Personal');
  }
}
