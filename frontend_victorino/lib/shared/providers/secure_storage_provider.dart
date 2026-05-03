// Provider del SecureStorage. Una sola instancia compartida en toda la app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage/secure_storage.dart';

// flutter_secure_storage 10+ migra automáticamente a cifrado AES nativo;
// ya no se necesita encryptedSharedPreferences.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});
