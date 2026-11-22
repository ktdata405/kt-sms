class ClassifiedSms {
  final String category; // Personal, Transactions, OTPs, Promotions, Bills, Spam
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
    final upperSender = sender.toUpperCase();

    // 1. Strict OTP Detection
    if (lowerBody.contains('otp') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('one-time password') ||
        lowerBody.contains('security code') ||
        lowerBody.contains('code is')) {
      final otpRegExp = RegExp(r'\b\d{4,8}\b');
      final match = otpRegExp.firstMatch(body);
      return ClassifiedSms(
        category: 'OTPs',
        otpCode: match?.group(0),
      );
    }

    // 2. Strict Transaction Detection (Debited / Credited / UPI / A/c)
    if (lowerBody.contains('debited') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('received') ||
        lowerBody.contains('a/c') ||
        lowerBody.contains('upi') ||
        lowerBody.contains('balance') ||
        lowerBody.contains('rs.') ||
        lowerBody.contains('inr')) {

      final amountRegExp = RegExp(r'(?:[₹]|Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false);
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

    // 3. Strict Bill / Reminder Detection
    if (lowerBody.contains('bill') ||
        lowerBody.contains('due') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('emi') ||
        lowerBody.contains('renewal')) {

      final amountRegExp = RegExp(r'(?:[₹]|Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false);
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

    // 4. Strict Promotion Detection (Shortcode senders or offer keywords)
    final isShortCode = upperSender.length <= 7 && !upperSender.contains(RegExp(r'^\+?[0-9]+$'));
    if (isShortCode ||
        lowerBody.contains('offer') ||
        lowerBody.contains('discount') ||
        lowerBody.contains('sale') ||
        lowerBody.contains('cashback') ||
        lowerBody.contains('promo') ||
        lowerBody.contains('off') ||
        lowerBody.contains('scratch card')) {
      return ClassifiedSms(category: 'Promotions');
    }

    // 5. Default to Personal
    return ClassifiedSms(category: 'Personal');
  }
}
