// GAP-048: Offline Sync Service
//
// This service is responsible for:
// - Detecting connectivity changes
// - Draining the OfflinePaymentQueue when back online
// - Using the existing PaymentService.insertPayment API to persist to Supabase
// - Updating sync_status semantics at the application level
//
// NOTE:
// - This implementation expects `connectivity_plus` to be added as a dependency:
//     connectivity_plus: ^6.0.0
// - Wire `start()` early in app startup (e.g. after auth/login is ready).

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'offline_payment_queue.dart';
import 'payment_service.dart';
import 'network_service.dart';
import 'conflict_resolution_service.dart';

class OfflineSyncService {
  OfflineSyncService._internal();

  static final OfflineSyncService instance = OfflineSyncService._internal();

  final Connectivity _connectivity = Connectivity();

  // FIX: connectivity_plus v6 returns List<ConnectivityResult>
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isSyncing = false;

  /// Start listening for connectivity changes and auto-sync when back online.
  void start() {
    // Avoid double subscriptions
    _subscription?.cancel();

    _subscription = _connectivity.onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
        final result = results.isNotEmpty
            ? results.first
            : ConnectivityResult.none;

        final online = result != ConnectivityResult.none;
        if (online) {
          _triggerSync();
        }
      },
    );

    // Attempt a sync on startup in case we are already online.
    _triggerSync();
  }

  /// Stop listening for connectivity changes.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Public method to force a sync (e.g. pull-to-refresh in UI).
  Future<void> syncNow() => _syncQueuedPayments();

  void _triggerSync() {
    // Fire-and-forget; errors are logged.
    _syncQueuedPayments();
  }

  Future<void> _syncQueuedPayments() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (!await OfflinePaymentQueue.hasItems()) return;

      final items = await OfflinePaymentQueue.drain();
      debugPrint(
        'OfflineSyncService: Starting sync of ${items.length} payments',
      );

      int syncedCount = 0;
      int skippedCount = 0;
      int failedCount = 0;

      for (final item in items) {
        try {
          // Check for conflicts before syncing
          final conflictCheck = await ConflictResolutionService.instance.checkConflict(item);
          
          if (conflictCheck.hasConflict) {
            debugPrint(
              'OfflineSyncService: Conflict detected for payment '
              '(clientPaymentId: ${item.clientPaymentId}, type: ${conflictCheck.conflictType})',
            );
            
            final shouldProceed = await ConflictResolutionService.instance.handleConflict(
              item,
              conflictCheck,
            );
            
            if (!shouldProceed) {
              skippedCount++;
              debugPrint(
                'OfflineSyncService: Skipping payment due to conflict: ${conflictCheck.conflictMessage}',
              );
              continue; // Skip this payment
            }
          }

          // PaymentService.insertPayment already uses NetworkService.retry internally
          // But we'll wrap it in an additional retry layer for offline sync
          await NetworkService.retry(
            maxRetries: 2, // Additional retries for sync
            timeout: 20,
            fn: () => PaymentService.insertPayment(
              userSchemeId: item.userSchemeId,
              customerId: item.customerId,
              staffId: item.staffId,
              amount: item.amount,
              paymentMethod: item.paymentMethod,
              metalRatePerGram: item.metalRatePerGram,
              deviceId: item.deviceId,
              clientTimestamp: item.clientTimestamp,
            ),
          );
          syncedCount++;
          debugPrint(
            'OfflineSyncService: Successfully synced payment for customer ${item.customerId}',
          );
        } catch (e, stack) {
          failedCount++;
          
          // Check if error is a conflict/duplicate error
          if (ConflictResolutionService.isConflictError(e)) {
            debugPrint(
              'OfflineSyncService: Payment conflict detected at database level. '
              'Skipping duplicate payment (clientPaymentId: ${item.clientPaymentId})',
            );
            skippedCount++;
            // Don't re-queue conflict errors
            continue;
          }
          
          debugPrint(
            'OfflineSyncService: payment sync failed, re-queuing. Error: $e',
          );
          debugPrintStack(stackTrace: stack);

          // Re-queue the item for next sync attempt (only for non-conflict errors)
          await OfflinePaymentQueue.enqueue(item);
        }
      }
      
      debugPrint(
        'OfflineSyncService: Sync completed. '
        'Synced: $syncedCount, Skipped: $skippedCount, Failed: $failedCount',
      );
    } catch (e, stack) {
      debugPrint(
        'OfflineSyncService: unexpected error during sync: $e',
      );
      debugPrintStack(stackTrace: stack);
    } finally {
      _isSyncing = false;
    }
  }
}
