import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

final lockServiceProvider = Provider<LockService>((ref) {
  return LockService();
});

class LockService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final _localAuth = LocalAuthentication();

  static const _keyPin = 'app_lock_pin';
  static const _keyQuestion = 'app_lock_qa_question';
  static const _keyAnswer = 'app_lock_qa_answer';
  static const _keyEnabled = 'app_lock_enabled';

  // Hashing helper (robust)
  String _hash(String input) {
    if (input.isEmpty) return '';
    return sha256.convert(utf8.encode(input.trim())).toString();
  }

  // Check if lock is enabled
  Future<bool> isLockEnabled() async {
    final enabled = await _storage.read(key: _keyEnabled);
    return enabled == 'true';
  }

  // Check if setup is complete (has PIN)
  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _keyPin);
    return pin != null && pin.isNotEmpty;
  }

  // Set PIN and Recovery
  Future<void> setupLock(String pin, String question, String answer) async {
    final pinHash = _hash(pin);
    await _storage.write(key: _keyPin, value: pinHash);
    await _storage.write(key: _keyQuestion, value: question.trim());
    await _storage.write(key: _keyAnswer, value: _hash(answer));
    await _storage.write(key: _keyEnabled, value: 'true');

    // VERIFY WRITE IMMEDIATELY
    final storedHash = await _storage.read(key: _keyPin);
    if (storedHash != pinHash) {
      throw Exception('저장소 오류: 데이터가 올바르게 저장되지 않았습니다. 다시 시도해주세요.');
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _keyPin);
    if (storedHash == null) return false;
    // Compare hashed inputs
    return storedHash == _hash(pin);
  }

  // Verify Recovery Answer
  Future<bool> verifyRecoveryAnswer(String answer) async {
    final storedHash = await _storage.read(key: _keyAnswer);
    if (storedHash == null) return false;
    return storedHash == _hash(answer.toLowerCase().trim());
  }

  // Get Recovery Question
  Future<String?> getRecoveryQuestion() async {
    return await _storage.read(key: _keyQuestion);
  }

  // Enable Lock (without changing PIN)
  Future<void> enableLock() async {
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  // Disable Lock (keep PIN)
  Future<void> disableLock() async {
    await _storage.write(key: _keyEnabled, value: 'false');
  }

  // Reset Lock (clear PIN and Disable)
  Future<void> resetLock() async {
    await _storage.delete(key: _keyPin);
    await _storage.delete(key: _keyQuestion);
    await _storage.delete(key: _keyAnswer);
    await _storage.write(key: _keyEnabled, value: 'false');
  }

  // Biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: '앱 잠금을 해제하려면 인증해주세요',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
