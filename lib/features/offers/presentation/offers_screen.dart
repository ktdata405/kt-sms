import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Promotions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: const Icon(Icons.local_offer),
              ),
              title: Text('Exclusive Offer #${index + 1}'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Get 50% off on your next purchase using code KT50. Valid till end of month.'),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.block),
                onPressed: () {
                  // Unsubscribe/block sender
                },
                tooltip: 'Unsubscribe',
              ),
            ),
          );
        },
      ),
    );
  }
}
