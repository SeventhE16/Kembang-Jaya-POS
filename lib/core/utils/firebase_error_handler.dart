import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getMessage(dynamic exception) {
    if (exception is FirebaseAuthException) {
      switch (exception.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-not-found':
          return 'Akun dengan email ini tidak ditemukan.';
        case 'wrong-password':
          return 'Kata sandi yang Anda masukkan salah.';
        case 'invalid-credential':
          return 'Email atau kata sandi salah. Silakan periksa kembali.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan. Hubungi administrator.';
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Gunakan email lain.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
        case 'operation-not-allowed':
          return 'Login gagal: Metode otentikasi tidak diizinkan.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Akun Anda diblokir sementara. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
        default:
          return 'Terjadi kesalahan sistem: ${exception.message ?? exception.code}';
      }
    }
    
    // For non-Firebase auth errors
    final String errorString = exception.toString();
    if (errorString.startsWith('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    }
    return 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
  }
}
