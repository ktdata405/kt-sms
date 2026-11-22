class ClassifiedSms {
  // Personal, Transactions, OTPs, Promotions, Bills, Spam
  final String category;
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
  static final RegExp _amountRegExp = RegExp(
    r'(?:₹|Rs\.?|INR)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _otpRegExp = RegExp(r'\b\d{4,8}\b');

  static const List<String> _otpKeywords = [
    ' otp ',
    'otp',
    'one time password',
    'one-time password',
    'verification code',
    'security code',
    'passcode',
    'login code',
  ];

  static const List<String> _transactionKeywords = [
    'debited',
    'credited',
    'withdrawn',
    'deposited',
    'spent',
    'received',
    'sent',
    'upi',
    'imps',
    'neft',
    'rtgs',
    'card ending',
    'a/c',
    'account',
    'avail bal',
    'available balance',
    'txn',
    'transaction',
  ];

  static const List<String> _billKeywords = [
    'bill due',
    'due date',
    'payment due',
    'minimum due',
    'outstanding',
    'electricity bill',
    'water bill',
    'gas bill',
    'broadband bill',
    'postpaid bill',
    'credit card bill',
    'emi due',
    'recharge due',
    'renewal due',
    'last date to pay',
  ];

  static const List<String> _promotionKeywords = [
    'offer',
    'discount',
    'sale',
    'cashback',
    'promo',
    'coupon',
    'deal',
    'flat',
    '% off',
    'buy 1 get',
    'limited period',
    'subscribe',
    'unsubscribe',
    'stop to opt out',
    'exclusive',
  ];

  static const List<String> _bankSenderHints = [
    'BANK',
    'HDFC',
    'ICICI',
    'SBI',
    'AXIS',
    'KOTAK',
    'PAYTM',
    'PHONEPE',
    'GPAY',
    'AMEX',
  ];

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static double? _extractAmount(String body) {
    final match = _amountRegExp.firstMatch(body);
    if (match == null || match.group(1) == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  static DateTime? _extractDueDate(String body) {
    final now = DateTime.now();
    final lowerBody = body.toLowerCase();

    final ddMon = RegExp(
      r'\b(?:on|by|before|due)\s+(\d{1,2})\s*[-/\s]?\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\b',
      caseSensitive: false,
    );
    final ddMmYyyy = RegExp(
      r'\b(?:on|by|before|due)\s+(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
      caseSensitive: false,
    );

    final monthMap = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final monMatch = ddMon.firstMatch(lowerBody);
    if (monMatch != null) {
      final day = int.tryParse(monMatch.group(1) ?? '');
      final month = monthMap[monMatch.group(2) ?? ''];
      if (day != null && month != null) {
        var year = now.year;
        var parsed = DateTime(year, month, day);
        if (parsed.isBefore(now.subtract(const Duration(days: 1)))) {
          parsed = DateTime(year + 1, month, day);
        }
        return parsed;
      }
    }

    final numericMatch = ddMmYyyy.firstMatch(lowerBody);
    if (numericMatch != null) {
      final day = int.tryParse(numericMatch.group(1) ?? '');
      final month = int.tryParse(numericMatch.group(2) ?? '');
      final yearRaw = numericMatch.group(3);
      int year;
      if (yearRaw == null) {
        year = now.year;
      } else if (yearRaw.length == 2) {
        year = 2000 + (int.tryParse(yearRaw) ?? now.year % 100);
      } else {
        year = int.tryParse(yearRaw) ?? now.year;
      }
      if (day != null && month != null) {
        return DateTime(year, month, day);
      }
    }

    if (lowerBody.contains('tomorrow')) return now.add(const Duration(days: 1));
    if (lowerBody.contains('today')) return now;
    return null;
  }

  static ClassifiedSms classify(String sender, String body) {
    final lowerBody = body.toLowerCase();
    final upperSender = sender.toUpperCase();
    final amount = _extractAmount(body);

    // 1. OTP detection
    if (_containsAny(lowerBody, _otpKeywords)) {
      final match = _otpRegExp.firstMatch(body);
      return ClassifiedSms(category: 'OTPs', otpCode: match?.group(0));
    }

    // 2. Bill / reminder detection
    final isBill = _containsAny(lowerBody, _billKeywords);
    if (isBill) {
      return ClassifiedSms(
        category: 'Bills',
        amount: amount,
        merchant: sender,
        dueDate: _extractDueDate(body),
      );
    }

    // 3. Transaction detection
    final hasTxnKeyword = _containsAny(lowerBody, _transactionKeywords);
    final hasBankSenderHint = _bankSenderHints.any(upperSender.contains);
    if (hasTxnKeyword || (amount != null && hasBankSenderHint)) {
      return ClassifiedSms(
        category: 'Transactions',
        amount: amount,
        merchant: sender,
      );
    }

    // 4. Promotion detection
    if (_containsAny(lowerBody, _promotionKeywords)) {
      return ClassifiedSms(category: 'Promotions');
    }

    // 5. Default
    return ClassifiedSms(category: 'Personal');
  }
}
