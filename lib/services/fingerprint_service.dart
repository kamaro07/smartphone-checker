import 'package:local_auth/local_auth.dart';

class FingerprintService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> test() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Teste de impressão digital',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
