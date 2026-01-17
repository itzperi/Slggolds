// test/services/offline_payment_queue_test.dart
//
// GAP-047: Offline Payment Queue Tests
//
// Tests for offline payment queue functionality:
// - Enqueue payments
// - Queue limit enforcement
// - Drain queue
// - Queue persistence

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slg_thangangal/services/offline_payment_queue.dart';

void main() {
  group('OfflinePaymentQueue Tests (GAP-047)', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await OfflinePaymentQueue.clear();
    });

    test('should enqueue payment successfully', () async {
      final item = OfflinePaymentQueueItem(
        customerId: 'customer-1',
        userSchemeId: 'scheme-1',
        staffId: 'staff-1',
        amount: 100.0,
        paymentMethod: 'cash',
        metalRatePerGram: 6500.0,
        deviceId: 'device-1',
        clientTimestamp: DateTime.now(),
        clientPaymentId: 'payment-1',
      );

      await OfflinePaymentQueue.enqueue(item);
      final size = await OfflinePaymentQueue.size();
      expect(size, 1);
    });

    test('should enforce queue limit', () async {
      // Fill queue to limit
      for (int i = 0; i < kOfflineQueueLimit; i++) {
        final item = OfflinePaymentQueueItem(
          customerId: 'customer-$i',
          userSchemeId: 'scheme-$i',
          staffId: 'staff-1',
          amount: 100.0,
          paymentMethod: 'cash',
          metalRatePerGram: 6500.0,
          deviceId: 'device-1',
          clientTimestamp: DateTime.now(),
          clientPaymentId: 'payment-$i',
        );
        await OfflinePaymentQueue.enqueue(item);
      }

      // Next enqueue should fail
      final item = OfflinePaymentQueueItem(
        customerId: 'customer-overflow',
        userSchemeId: 'scheme-overflow',
        staffId: 'staff-1',
        amount: 100.0,
        paymentMethod: 'cash',
        metalRatePerGram: 6500.0,
        deviceId: 'device-1',
        clientTimestamp: DateTime.now(),
        clientPaymentId: 'payment-overflow',
      );

      expect(
        () => OfflinePaymentQueue.enqueue(item),
        throwsA(isA<OfflineQueueFullException>()),
      );
    });

    test('should drain queue in FIFO order', () async {
      // Enqueue multiple items
      for (int i = 0; i < 5; i++) {
        final item = OfflinePaymentQueueItem(
          customerId: 'customer-$i',
          userSchemeId: 'scheme-$i',
          staffId: 'staff-1',
          amount: 100.0 + i,
          paymentMethod: 'cash',
          metalRatePerGram: 6500.0,
          deviceId: 'device-1',
          clientTimestamp: DateTime.now(),
          clientPaymentId: 'payment-$i',
        );
        await OfflinePaymentQueue.enqueue(item);
      }

      final drained = await OfflinePaymentQueue.drain();
      expect(drained.length, 5);
      expect(drained[0].amount, 100.0); // First item should be first
      expect(drained[4].amount, 104.0); // Last item should be last

      // Queue should be empty after drain
      final size = await OfflinePaymentQueue.size();
      expect(size, 0);
    });

    test('should persist queue across app restarts', () async {
      final item = OfflinePaymentQueueItem(
        customerId: 'customer-1',
        userSchemeId: 'scheme-1',
        staffId: 'staff-1',
        amount: 100.0,
        paymentMethod: 'cash',
        metalRatePerGram: 6500.0,
        deviceId: 'device-1',
        clientTimestamp: DateTime.now(),
        clientPaymentId: 'payment-1',
      );

      await OfflinePaymentQueue.enqueue(item);

      // Simulate app restart by creating new instance
      final items = await OfflinePaymentQueue.loadQueue();
      expect(items.length, 1);
      expect(items[0].customerId, 'customer-1');
    });
  });
}

