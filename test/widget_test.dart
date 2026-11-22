import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kt_sms/main.dart';

void main() {
  testWidgets('KT-SMS App loads bottom navigation and inbox', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: KtSmsApp()));

    // Verify app title / header
    expect(find.text('KT - SMS Organizer'), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('Inbox'), findsAtLeastNWidgets(1));
    expect(find.text('Transactions'), findsAtLeastNWidgets(1));
    expect(find.text('Reminders'), findsAtLeastNWidgets(1));
    expect(find.text('Offers'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });
}
