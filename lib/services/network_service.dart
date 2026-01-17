// lib/services/network_service.dart
//
// NetworkService: Retry logic with exponential backoff
//
// This service provides:
// - Automatic retry for transient network errors
// - Exponential backoff (1s, 2s, 4s)
// - Network connectivity detection
// - Error classification (retryable vs non-retryable)
// - Configurable retry attempts and timeouts
//
// Usage:
//   final result = await NetworkService.retry(
//     () => supabase.from('table').select(),
//     maxRetries: 3,
//   );

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RetryableErrorType {
  network,
  timeout,
  serverError,
  unknown,
}

enum NonRetryableErrorType {
  authentication,
  authorization,
  validation,
  notFound,
  conflict,
  unknown,
}

class NetworkService {
  NetworkService._internal();
  static final NetworkService instance = NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has network connectivity
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty &&
          result.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('NetworkService: Error checking connectivity: $e');
      return false;
    }
  }

  /// Retry a function with exponential backoff
  /// 
  /// [fn] - The function to retry
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay in seconds before first retry (default: 1)
  /// [maxDelay] - Maximum delay between retries in seconds (default: 8)
  /// [timeout] - Total timeout in seconds for all attempts (default: 30)
  /// [shouldRetry] - Optional function to determine if error should be retried
  static Future<T> retry<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    int initialDelay = 1,
    int maxDelay = 8,
    int timeout = 30,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final startTime = DateTime.now();
    int attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        // Check timeout
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        if (elapsed >= timeout) {
          throw TimeoutException(
            'Operation timed out after $timeout seconds',
            Duration(seconds: timeout),
          );
        }

        // Execute the function
        return await fn();
      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Check if error should be retried
        if (shouldRetry != null && !shouldRetry(e)) {
          debugPrint('NetworkService: Non-retryable error: $e');
          rethrow;
        }

        // Check if error is non-retryable by default
        if (_isNonRetryableError(e)) {
          debugPrint('NetworkService: Non-retryable error detected: $e');
          rethrow;
        }

        // Check if we've exhausted retries
        if (attempt >= maxRetries) {
          debugPrint(
            'NetworkService: Max retries ($maxRetries) exhausted. Last error: $e',
          );
          rethrow;
        }

        // Check connectivity before retrying
        final isConnected = await NetworkService.instance.isConnected();
        if (!isConnected) {
          debugPrint('NetworkService: No connectivity, not retrying');
          throw SocketException('No internet connection');
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt, initialDelay, maxDelay);
        debugPrint(
          'NetworkService: Retry attempt ${attempt + 1}/$maxRetries after ${delay}s. Error: $e',
        );

        // Wait before retrying
        await Future.delayed(Duration(seconds: delay));
        attempt++;
      }
    }

    // Should never reach here, but just in case
    throw lastException ?? Exception('Unknown error occurred');
  }

  /// Calculate exponential backoff delay
  static int _calculateDelay(int attempt, int initialDelay, int maxDelay) {
    final delay = initialDelay * (1 << attempt); // 1, 2, 4, 8, ...
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Check if error is non-retryable (should not be retried)
  static bool _isNonRetryableError(dynamic error) {
    // Authentication errors
    if (error is AuthException) {
      return true;
    }

    // Postgrest errors (Supabase database errors)
    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message?.toLowerCase() ?? '';

      // Non-retryable error codes
      // 23505: unique_violation (conflict)
      // 23503: foreign_key_violation (validation)
      // 23514: check_violation (validation)
      // 42501: insufficient_privilege (authorization)
      // 42P01: undefined_table (not found)
      // 42703: undefined_column (not found)
      if (code == '23505' || // unique_violation
          code == '23503' || // foreign_key_violation
          code == '23514' || // check_violation
          code == '42501' || // insufficient_privilege
          code == '42P01' || // undefined_table
          code == '42703') {
        // undefined_column
        return true;
      }

      // RLS policy violations (authorization)
      if (message.contains('row-level security') ||
          message.contains('policy violation') ||
          message.contains('permission denied')) {
        return true;
      }

      // Validation errors
      if (message.contains('violates') ||
          message.contains('constraint') ||
          message.contains('invalid')) {
        return true;
      }

      // 5xx errors are retryable (server errors)
      // 4xx errors (except 401, 403) might be retryable for transient issues
      // But we'll be conservative and not retry most 4xx errors
      if (code != null && code.startsWith('4')) {
        // 401, 403 are definitely non-retryable
        if (code == '401' || code == '403') {
          return true;
        }
        // Other 4xx might be retryable (e.g., 429 rate limit, 408 timeout)
        // But we'll treat them as non-retryable for safety
        return true;
      }
    }

    // Format errors (validation)
    if (error is FormatException) {
      return true;
    }

    // Socket errors are retryable (network issues)
    if (error is SocketException) {
      return false; // Retry network errors
    }

    // Timeout errors are retryable
    if (error is TimeoutException) {
      return false; // Retry timeout errors
    }

    // Default: retry unknown errors (might be transient)
    return false;
  }

  /// Classify error type for logging/debugging
  static RetryableErrorType? classifyRetryableError(dynamic error) {
    if (error is SocketException) {
      return RetryableErrorType.network;
    }
    if (error is TimeoutException) {
      return RetryableErrorType.timeout;
    }
    if (error is PostgrestException) {
      final code = error.code;
      if (code != null && code.startsWith('5')) {
        return RetryableErrorType.serverError;
      }
    }
    if (!_isNonRetryableError(error)) {
      return RetryableErrorType.unknown;
    }
    return null;
  }

  /// Classify non-retryable error type for logging/debugging
  static NonRetryableErrorType classifyNonRetryableError(dynamic error) {
    if (error is AuthException) {
      return NonRetryableErrorType.authentication;
    }
    if (error is PostgrestException) {
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('row-level security') ||
          message.contains('policy violation') ||
          message.contains('permission denied') ||
          error.code == '42501') {
        return NonRetryableErrorType.authorization;
      }
      if (message.contains('violates') ||
          message.contains('constraint') ||
          message.contains('invalid') ||
          error.code == '23505' ||
          error.code == '23503' ||
          error.code == '23514') {
        return NonRetryableErrorType.validation;
      }
      if (error.code == '42P01' || error.code == '42703') {
        return NonRetryableErrorType.notFound;
      }
      if (error.code == '23505') {
        return NonRetryableErrorType.conflict;
      }
    }
    if (error is FormatException) {
      return NonRetryableErrorType.validation;
    }
    return NonRetryableErrorType.unknown;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is AuthException) {
      return 'Authentication failed. Please log in again.';
    }
    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message ?? 'Database error occurred.';

      if (code == '42501' ||
          message.toLowerCase().contains('permission denied') ||
          message.toLowerCase().contains('row-level security')) {
        return 'You do not have permission to perform this action.';
      }
      if (code == '23505') {
        return 'This record already exists.';
      }
      if (code == '23503') {
        return 'Invalid reference. Please check your input.';
      }
      if (code == '23514') {
        return 'Invalid data. Please check your input.';
      }
      if (code != null && code.startsWith('5')) {
        return 'Server error. Please try again later.';
      }
      return message;
    }
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

