// lib/services/fingerprint_service.dart
import 'package:local_auth/local_auth.dart';

class FingerprintService {
  static final _auth = LocalAuthentication();

  static Future<String> check() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return 'Biometrics not available';
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to test fingerprint',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      return didAuthenticate ? 'Success' : 'Success_WrongFinger';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
