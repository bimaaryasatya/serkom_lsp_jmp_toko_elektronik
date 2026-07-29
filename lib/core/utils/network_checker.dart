import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class NetworkChecker {
  static DateTime? _lastSnackbarTime;

  /// Memeriksa apakah server backend Flask dapat dijangkau
  static Future<bool> isServerReachable() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.apiBaseUrl.replaceFirst('/api', ''))).timeout(
        const Duration(seconds: 3),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Menampilkan SnackBar peringatan tidak ada internet / server offline
  static void showOfflineSnackBar(BuildContext context, {String? customMessage}) {
    // Hindari spamming snackbar jika baru ditampilkan dalam 5 detik terakhir
    if (_lastSnackbarTime != null && DateTime.now().difference(_lastSnackbarTime!) < const Duration(seconds: 5)) {
      return;
    }
    _lastSnackbarTime = DateTime.now();

    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                customMessage ?? 'Tidak ada koneksi internet / Server Flask offline',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
