// GAP-047: Offline Payment Queue Infrastructure
//
// This service provides a simple in-memory + local-storage backed queue
// for offline payment requests. It is intentionally focused on the
// minimum fields needed to re-construct a payment insert when back online.
//
// Storage backend:
// - Uses `SharedPreferences` to persist a JSON-encoded list.
// - You can later swap this to `sqflite` if you need richer querying.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _offlineQueueStorageKey = 'offline_payments_queue_v1';

/// Max number of queued payments. Additional enqueues will fail
/// with [OfflineQueueFullException].
const int kOfflineQueueLimit = 100;

class OfflineQueueFullException implements Exception {
  final String message;
  OfflineQueueFullException(this.message);

  @override
  String toString() => 'OfflineQueueFullException: $message';
}

class OfflinePaymentQueueItem {
  final String customerId;
  final String userSchemeId;
  final String staffId;
  final double amount;
  final String paymentMethod;
  final double metalRatePerGram;
  final String deviceId;
  final DateTime clientTimestamp;

  /// Optional client-generated UUID for idempotency / conflict resolution.
  final String clientPaymentId;

  OfflinePaymentQueueItem({
    required this.customerId,
    required this.userSchemeId,
    required this.staffId,
    required this.amount,
    required this.paymentMethod,
    required this.metalRatePerGram,
    required this.deviceId,
    required this.clientTimestamp,
    required this.clientPaymentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'userSchemeId': userSchemeId,
      'staffId': staffId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'metalRatePerGram': metalRatePerGram,
      'deviceId': deviceId,
      'clientTimestamp': clientTimestamp.toIso8601String(),
      'clientPaymentId': clientPaymentId,
    };
  }

  static OfflinePaymentQueueItem fromJson(Map<String, dynamic> json) {
    return OfflinePaymentQueueItem(
      customerId: json['customerId'] as String,
      userSchemeId: json['userSchemeId'] as String,
      staffId: json['staffId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      metalRatePerGram: (json['metalRatePerGram'] as num).toDouble(),
      deviceId: json['deviceId'] as String,
      clientTimestamp: DateTime.parse(json['clientTimestamp'] as String),
      clientPaymentId: json['clientPaymentId'] as String,
    );
  }
}

class OfflinePaymentQueue {
  OfflinePaymentQueue._();

  /// Returns the current queue items (oldest first).
  static Future<List<OfflinePaymentQueueItem>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineQueueStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => OfflinePaymentQueueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists the whole queue atomically.
  static Future<void> _saveQueue(List<OfflinePaymentQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_offlineQueueStorageKey, encoded);
  }

  /// Enqueue a payment for later sync.
  ///
  /// Throws [OfflineQueueFullException] if the queue has reached the limit.
  static Future<void> enqueue(OfflinePaymentQueueItem item) async {
    final items = await loadQueue();
    if (items.length >= kOfflineQueueLimit) {
      throw OfflineQueueFullException(
        'Offline payment queue limit ($kOfflineQueueLimit) reached',
      );
    }

    items.add(item);
    await _saveQueue(items);
  }

  /// Dequeues all items in FIFO order and clears the queue.
  ///
  /// The caller (e.g. OfflineSyncService) is responsible for
  /// iterating and attempting sync for each item.
  static Future<List<OfflinePaymentQueueItem>> drain() async {
    final items = await loadQueue();
    await clear();
    return items;
  }

  /// Clears the entire queue.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineQueueStorageKey);
  }

  /// Returns true if there is at least one queued payment.
  static Future<bool> hasItems() async {
    final items = await loadQueue();
    return items.isNotEmpty;
  }

  /// Returns the current size of the queue.
  static Future<int> size() async {
    final items = await loadQueue();
    return items.length;
  }
}


