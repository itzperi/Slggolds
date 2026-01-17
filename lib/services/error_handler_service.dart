// lib/services/error_handler_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error handling service
/// Provides consistent error handling, logging, and user-friendly error messages
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Handle and log errors consistently
  /// 
  /// [error] - The error/exception that occurred
  /// [stackTrace] - Optional stack trace
  /// [context] - Optional BuildContext for showing error messages
  /// [userMessage] - Optional custom user-friendly message
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    BuildContext? context,
    String? userMessage,
  }) {
    // Log error
    if (kDebugMode) {
      debugPrint('ErrorHandlerService: ${error.toString()}');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // TODO: Send to error tracking service (Sentry) when integrated
    // if (sentryDsn != null && sentryDsn.isNotEmpty) {
    //   Sentry.captureException(error, stackTrace: stackTrace);
    // }

    // Show user-friendly message if context is provided
    if (context != null && userMessage != null) {
      _showErrorSnackBar(context, userMessage);
    }
  }

  /// Get user-friendly error message from exception
  /// 
  /// Converts technical errors to user-friendly messages
  String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Authentication errors
    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('invalid') ||
        errorString.contains('expired')) {
      return 'Authentication error. Please log in again.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('server') ||
        errorString.contains('internal')) {
      return 'Server error. Please try again later.';
    }

    // Not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      // Try to extract the actual validation message
      final match = RegExp(r'([^:]+)$').firstMatch(error.toString());
      if (match != null) {
        return match.group(1)?.trim() ?? 'Invalid input. Please check your data.';
      }
      return 'Invalid input. Please check your data.';
    }

    // Default message
    // Remove "Exception: " prefix if present
    final cleanedMessage = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    
    // If the error message is too technical, use a generic message
    if (cleanedMessage.contains('at ') || cleanedMessage.contains('package:')) {
      return 'An error occurred. Please try again.';
    }

    return cleanedMessage.isNotEmpty ? cleanedMessage : 'An unexpected error occurred.';
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Handle API errors consistently
  /// 
  /// Extracts error message from Supabase/API responses
  String extractApiErrorMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      // Supabase error format
      if (error.containsKey('message')) {
        return error['message'] as String;
      }
      if (error.containsKey('error')) {
        final errorObj = error['error'];
        if (errorObj is String) {
          return errorObj;
        }
        if (errorObj is Map && errorObj.containsKey('message')) {
          return errorObj['message'] as String;
        }
      }
    }

    return getUserFriendlyMessage(error);
  }
}

