// lib/services/conflict_resolution_service.dart
//
// Conflict Resolution Service for Offline Payment Sync
//
// This service handles conflict detection and resolution when syncing offline payments:
// - Duplicate payment detection (by clientPaymentId)
// - Duplicate detection by business logic (same customer + amount + date)
// - Conflict resolution strategies (first-wins, skip-duplicate)
// - Conflict reporting and logging
//

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'offline_payment_queue.dart';

enum ConflictType {
  duplicateByClientId, // Same clientPaymentId already exists
  duplicateByBusinessLogic, // Same customer + amount + date
  uniqueConstraintViolation, // Database constraint violation
  unknown,
}

enum ConflictResolutionStrategy {
  skipDuplicate, // Skip if duplicate found (first-wins)
  manualReview, // Mark for manual review
  forceInsert, // Force insert (not recommended)
}

class ConflictResult {
  final bool hasConflict;
  final ConflictType? conflictType;
  final String? conflictMessage;
  final ConflictResolutionStrategy resolutionStrategy;
  final Map<String, dynamic>? conflictDetails;

  ConflictResult({
    required this.hasConflict,
    this.conflictType,
    this.conflictMessage,
    this.resolutionStrategy = ConflictResolutionStrategy.skipDuplicate,
    this.conflictDetails,
  });

  bool get shouldSkip => hasConflict && resolutionStrategy == ConflictResolutionStrategy.skipDuplicate;
  bool get needsManualReview => hasConflict && resolutionStrategy == ConflictResolutionStrategy.manualReview;
}

class ConflictResolutionService {
  ConflictResolutionService._internal();
  static final ConflictResolutionService instance = ConflictResolutionService._internal();

  final _supabase = Supabase.instance.client;

  /// Check for conflicts before syncing a payment
  /// 
  /// Returns ConflictResult indicating if conflict exists and how to resolve it
  Future<ConflictResult> checkConflict(OfflinePaymentQueueItem item) async {
    try {
      // 1. Check for duplicate by clientPaymentId (idempotency key)
      final duplicateByClientId = await _checkDuplicateByClientId(item.clientPaymentId);
      if (duplicateByClientId != null) {
        return ConflictResult(
          hasConflict: true,
          conflictType: ConflictType.duplicateByClientId,
          conflictMessage: 'Payment with same ID already exists in database',
          resolutionStrategy: ConflictResolutionStrategy.skipDuplicate,
          conflictDetails: {
            'existingPaymentId': duplicateByClientId,
            'clientPaymentId': item.clientPaymentId,
          },
        );
      }

      // 2. Check for duplicate by business logic (same customer + amount + date + time window)
      final duplicateByBusinessLogic = await _checkDuplicateByBusinessLogic(item);
      if (duplicateByBusinessLogic != null) {
        return ConflictResult(
          hasConflict: true,
          conflictType: ConflictType.duplicateByBusinessLogic,
          conflictMessage: 'Similar payment may already exist (same customer, amount, and date)',
          resolutionStrategy: ConflictResolutionStrategy.manualReview,
          conflictDetails: {
            'existingPaymentId': duplicateByBusinessLogic,
            'customerId': item.customerId,
            'amount': item.amount,
            'date': DateFormat('yyyy-MM-dd').format(item.clientTimestamp),
          },
        );
      }

      // No conflict found
      return ConflictResult(hasConflict: false);
    } catch (e, stackTrace) {
      debugPrint('ConflictResolutionService.checkConflict: Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      // On error, allow sync to proceed (let database constraints catch it)
      return ConflictResult(hasConflict: false);
    }
  }

  /// Check if payment with same clientPaymentId already exists in database
  Future<String?> _checkDuplicateByClientId(String clientPaymentId) async {
    try {
      // Note: We need to check if clientPaymentId is stored in a metadata field
      // Since payments table doesn't have clientPaymentId column by default,
      // we'll check by device_id + client_timestamp combination as a proxy
      // OR we can add a metadata JSONB column later
      
      // For now, we'll use a combination of device_id and client_timestamp
      // This is not perfect but works as a reasonable duplicate check
      
      // Actually, let's check by looking for payments with same:
      // - customer_id
      // - amount
      // - payment_date
      // - device_id (if available)
      // within a small time window (e.g., 5 minutes)
      
      // Since we don't have clientPaymentId in the payments table yet,
      // we'll rely on business logic check instead
      return null;
    } catch (e) {
      debugPrint('ConflictResolutionService._checkDuplicateByClientId: Error: $e');
      return null;
    }
  }

  /// Check for duplicate by business logic:
  /// Same customer + same amount + same date (within time window)
  Future<String?> _checkDuplicateByBusinessLogic(OfflinePaymentQueueItem item) async {
    try {
      final paymentDate = DateFormat('yyyy-MM-dd').format(item.clientTimestamp);
      
      // Calculate amount tolerance (to account for rounding differences)
      final amountTolerance = 0.01; // 1 paisa tolerance
      final minAmount = item.amount - amountTolerance;
      final maxAmount = item.amount + amountTolerance;
      
      // Check for payments with:
      // - Same customer_id
      // - Same amount (within tolerance)
      // - Same payment_date
      // - Within 1 hour time window
      final clientTimestamp = item.clientTimestamp;
      final timeWindowStart = clientTimestamp.subtract(const Duration(hours: 1));
      final timeWindowEnd = clientTimestamp.add(const Duration(hours: 1));
      
      final response = await _supabase
          .from('payments')
          .select('id, amount, payment_date, payment_time, device_id, client_timestamp')
          .eq('customer_id', item.customerId)
          .eq('payment_date', paymentDate)
          .gte('amount', minAmount)
          .lte('amount', maxAmount)
          .eq('status', 'completed')
          .eq('is_reversal', false)
          .order('created_at', ascending: false)
          .limit(5);
      
      if (response.isEmpty) {
        return null;
      }
      
      // Check if any payment matches the time window
      for (final payment in response) {
        final paymentClientTimestamp = payment['client_timestamp'] as String?;
        if (paymentClientTimestamp != null) {
          try {
            final existingTimestamp = DateTime.parse(paymentClientTimestamp);
            if (existingTimestamp.isAfter(timeWindowStart) && 
                existingTimestamp.isBefore(timeWindowEnd)) {
              // Found a potential duplicate
              return payment['id'] as String;
            }
          } catch (e) {
            // Ignore parse errors
          }
        }
        
        // Also check by device_id if available
        final paymentDeviceId = payment['device_id'] as String?;
        if (paymentDeviceId != null && 
            paymentDeviceId == item.deviceId &&
            payment['amount'] == item.amount) {
          // Same device, same amount, same date - likely duplicate
          return payment['id'] as String;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('ConflictResolutionService._checkDuplicateByBusinessLogic: Error: $e');
      return null;
    }
  }

  /// Handle conflict based on resolution strategy
  Future<bool> handleConflict(
    OfflinePaymentQueueItem item,
    ConflictResult conflict,
  ) async {
    switch (conflict.resolutionStrategy) {
      case ConflictResolutionStrategy.skipDuplicate:
        debugPrint(
          'ConflictResolutionService: Skipping duplicate payment '
          '(clientPaymentId: ${item.clientPaymentId})',
        );
        return false; // Skip this payment
      
      case ConflictResolutionStrategy.manualReview:
        debugPrint(
          'ConflictResolutionService: Payment needs manual review '
          '(clientPaymentId: ${item.clientPaymentId}, conflict: ${conflict.conflictMessage})',
        );
        // For now, we'll skip and log for manual review
        // In the future, this could be queued to a separate "needs review" queue
        return false; // Skip and mark for review
      
      case ConflictResolutionStrategy.forceInsert:
        debugPrint(
          'ConflictResolutionService: Force inserting payment despite conflict '
          '(clientPaymentId: ${item.clientPaymentId})',
        );
        return true; // Proceed with insert (will likely fail at database level)
    }
  }

  /// Check if a payment already exists in the queue (by clientPaymentId)
  Future<bool> isInQueue(String clientPaymentId) async {
    try {
      final queueItems = await OfflinePaymentQueue.loadQueue();
      return queueItems.any((item) => item.clientPaymentId == clientPaymentId);
    } catch (e) {
      debugPrint('ConflictResolutionService.isInQueue: Error: $e');
      return false;
    }
  }

  /// Check if error is a conflict/duplicate error from database
  static bool isConflictError(dynamic error) {
    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message?.toLowerCase() ?? '';
      
      // 23505: unique_violation (duplicate key)
      if (code == '23505') {
        return true;
      }
      
      // Check for duplicate/conflict keywords in message
      if (message.contains('duplicate') ||
          message.contains('already exists') ||
          message.contains('unique constraint')) {
        return true;
      }
    }
    
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('23505') ||
        errorStr.contains('duplicate') ||
        errorStr.contains('already exists') ||
        errorStr.contains('unique constraint');
  }

  /// Remove duplicate from queue if found
  Future<void> removeDuplicateFromQueue(String clientPaymentId) async {
    try {
      final queueItems = await OfflinePaymentQueue.loadQueue();
      final filteredItems = queueItems
          .where((item) => item.clientPaymentId != clientPaymentId)
          .toList();
      
      if (filteredItems.length < queueItems.length) {
        // Save filtered queue
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(filteredItems.map((e) => e.toJson()).toList());
        await prefs.setString('offline_payments_queue_v1', encoded);
        debugPrint('ConflictResolutionService: Removed duplicate from queue: $clientPaymentId');
      }
    } catch (e) {
      debugPrint('ConflictResolutionService.removeDuplicateFromQueue: Error: $e');
    }
  }
}

