import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

String mapAppError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (msg.contains('already registered')) {
      return 'Email ini sudah terdaftar.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum terverifikasi. Periksa kotak masuk Gmail Anda.';
    }
    if (msg.contains('token has expired') || msg.contains('otp_expired')) {
      return 'Kode verifikasi telah kedaluwarsa. Silakan kirim ulang kode baru.';
    }
    if (msg.contains('invalid') && msg.contains('otp') ||
        msg.contains('token is invalid')) {
      return 'Kode verifikasi tidak valid. Periksa kembali kode di email Anda.';
    }
    if (msg.contains('rate limit') || msg.contains('for security purposes')) {
      return 'Permintaan terlalu sering. Tunggu beberapa saat lalu coba lagi.';
    }
    return error.message;
  }
  if (error is PostgrestException) {
    if (error.message.contains('profiles_nrp_key')) {
      return 'NRP sudah terdaftar pada akun lain.';
    }
    if (error.message.contains('books_deskripsi_max_15_kata_chk')) {
      return 'Deskripsi buku maksimal 15 kata.';
    }
    return 'Gagal memproses data: ${error.message}';
  }
  if (error is StorageException) {
    return 'Gagal mengunggah gambar: ${error.message}';
  }
  if (error is SocketException) {
    return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
  }
  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
