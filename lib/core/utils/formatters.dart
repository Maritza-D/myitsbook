const List<String> kBookCategories = [
  'Buku Kuliah',
  'Kamus',
  'Novel',
  'Komik',
];

const List<String> kBookConditions = [
  'Seperti Baru',
  'Baik',
  'Cukup Baik',
];

const List<String> kCampusLocations = [
  'Gedung Sistem Informasi ITS',
  'Perpustakaan Pusat ITS',
  'Kantin Pusat ITS',
  'Asrama Mahasiswa ITS',
  'Bundaran ITS',
];

const int kMaxCoverFileBytes = 5 * 1024 * 1024;
const int kMaxDescriptionWords = 15;

const List<String> _indonesianMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

int countWords(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

String formatRupiah(int amount) {
  if (amount <= 0) return 'Gratis';
  final raw = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final posFromRight = raw.length - i;
    buf.write(raw[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buf.write('.');
    }
  }
  return 'Rp $buf';
}

String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${dateTime.day} ${_indonesianMonths[dateTime.month - 1]}';
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label wajib diisi';
  }
  return null;
}

String? validateEmail(String? value) {
  final requiredErr = validateRequired(value, 'Email');
  if (requiredErr != null) return requiredErr;
  final trimmed = value!.trim().toLowerCase();
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(trimmed)) {
    return 'Format email tidak valid';
  }
  const gmailTypos = {
    'gmai.com',
    'gmial.com',
    'gamil.com',
    'gmail.co',
    'gmail.con',
    'gmal.com',
  };
  final domain = trimmed.split('@').last;
  if (gmailTypos.contains(domain)) {
    return 'Domain email salah ketik (maksud Anda @gmail.com?)';
  }
  return null;
}

String? validateNrp(String? value) {
  final requiredErr = validateRequired(value, 'NRP');
  if (requiredErr != null) return requiredErr;
  final trimmed = value!.trim();
  if (!RegExp(r'^[0-9]{6,16}$').hasMatch(trimmed)) {
    return 'NRP harus berupa 6–16 digit angka';
  }
  return null;
}

String? validatePhone(String? value, {String label = 'Nomor telepon'}) {
  final requiredErr = validateRequired(value, label);
  if (requiredErr != null) return requiredErr;
  final digits = value!.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.length < 9 || digits.length > 15) {
    return '$label harus terdiri dari 9–15 digit';
  }
  return null;
}

String? validatePassword(String? value) {
  final requiredErr = validateRequired(value, 'Kata sandi');
  if (requiredErr != null) return requiredErr;
  if (value!.length < 6) {
    return 'Kata sandi minimal 6 karakter';
  }
  return null;
}

String? validateBookDescription(String? value) {
  final requiredErr = validateRequired(value, 'Deskripsi singkat');
  if (requiredErr != null) return requiredErr;
  final words = countWords(value!);
  if (words > kMaxDescriptionWords) {
    return 'Deskripsi maksimal $kMaxDescriptionWords kata (saat ini $words kata)';
  }
  return null;
}

String? validateBookPrice(String? value, {required bool isSale}) {
  if (!isSale) return null;
  final requiredErr = validateRequired(value, 'Harga buku');
  if (requiredErr != null) return requiredErr;
  final cleaned = value!.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(cleaned);
  if (parsed == null || parsed <= 0) {
    return 'Harga harus angka lebih dari 0';
  }
  return null;
}

String? validateCoverImageMeta({
  required String fileName,
  required int fileSizeBytes,
}) {
  final lower = fileName.toLowerCase();
  final validExt =
      lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  if (!validExt) {
    return 'Format foto sampul harus JPG atau PNG';
  }
  if (fileSizeBytes <= 0 || fileSizeBytes > kMaxCoverFileBytes) {
    return 'Ukuran foto sampul maksimal 5 MB';
  }
  return null;
}
