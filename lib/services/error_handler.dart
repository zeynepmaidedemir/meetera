import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Uygulama içi özelleştirilmiş hata sınıfı.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Firebase, Firestore, Storage ve Sistem hatalarını yakalayıp
/// kullanıcı dostu Türkçe mesajlara dönüştüren merkezi sınıf.
class ErrorMapper {
  static AppException fromError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is FirebaseAuthException) {
      return _mapAuthException(error);
    }

    if (error is FirebaseException) {
      return _mapFirebaseException(error);
    }

    if (error is PlatformException) {
      return AppException(
        error.message ?? "A system error occurred. Please try again.",
        code: error.code,
        originalError: error,
      );
    }

    if (error is SocketException) {
      return AppException(
        "No internet connection. Please check your network and try again.",
        code: "network-error",
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        "Operation timed out. Please try again later.",
        code: "timeout-error",
        originalError: error,
      );
    }

    // Bilinmeyen genel hatalar
    final errorString = error.toString().toLowerCase();
    if (errorString.contains("network-request-failed") || errorString.contains("network_error")) {
      return AppException(
        "Please check your internet connection and try again.",
        code: "network-error",
        originalError: error,
      );
    }

    return AppException(
      "An error occurred. Please try again later.",
      code: "unknown",
      originalError: error,
    );
  }

  static String getFriendlyMessage(dynamic error) {
    return fromError(error).message;
  }

  static AppException _mapAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = "This email is already registered. Please try logging in.";
        break;
      case 'invalid-email':
        message = "Please enter a valid email address.";
        break;
      case 'weak-password':
        message = "Your password is too weak. It must be at least 6 characters.";
        break;
      case 'wrong-password':
        message = "Incorrect password. Please try again.";
        break;
      case 'user-not-found':
        message = "No account found with this email address.";
        break;
      case 'user-disabled':
        message = "This account has been suspended by an administrator.";
        break;
      case 'operation-not-allowed':
        message = "This sign-in method is currently not enabled.";
        break;
      case 'network-request-failed':
        message = "Please check your internet connection and try again.";
        break;
      case 'too-many-requests':
        message = "Too many unsuccessful attempts. Please wait a moment and try again.";
        break;
      case 'requires-recent-login':
        message = "For security reasons, please log out and log in again before performing this action.";
        break;
      case 'popup-closed-by-user':
      case 'cancelled':
        message = "Sign-in cancelled.";
        break;
      default:
        message = e.message ?? "Authentication error. Please try again.";
    }
    return AppException(message, code: e.code, originalError: e);
  }

  static AppException _mapFirebaseException(FirebaseException e) {
    String message;
    switch (e.code) {
      case 'permission-denied':
        message = "You do not have permission to perform this action.";
        break;
      case 'unavailable':
        message = "Service is temporarily unavailable. Please try again later.";
        break;
      case 'not-found':
        message = "Requested data or file was not found.";
        break;
      case 'object-not-found':
        message = "The file to upload could not be found.";
        break;
      case 'quota-exceeded':
        message = "Storage quota exceeded. Please try again later.";
        break;
      case 'retry-limit-exceeded':
        message = "Operation timed out. Please try uploading again.";
        break;
      default:
        message = e.message ?? "A database or storage error occurred.";
    }
    return AppException(message, code: e.code, originalError: e);
  }
}

/// Uygulama genelinde premium ve tutarlı geri bildirimler sunmak için yardımcı UI fonksiyonları.
class UiHelpers {
  static void showPremiumSnackBar(
    BuildContext context, {
    required String message,
    bool isError = true,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isError
                ? [const Color(0xFFE11D48), const Color(0xFFBE123C)] // Premium Rose/Ruby gradient
                : [const Color(0xFF10B981), const Color(0xFF047857)], // Premium Emerald/Green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isError ? const Color(0xFFE11D48) : const Color(0xFF10B981)).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit', // Projedeki premium font
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  action.onPressed();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
