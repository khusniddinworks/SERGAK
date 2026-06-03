import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'uz';
  bool _vibrationEnabled = true;
  String _deviceId = '';
  String _premiumExpiry = '';
  String _installDate = '';

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get vibrationEnabled => _vibrationEnabled;
  String get deviceId => _deviceId;
  
  bool get isPremium {
    // 7 kunlik bepul sinov muddati
    if (_installDate.isNotEmpty) {
      final installDateTime = DateTime.tryParse(_installDate);
      if (installDateTime != null) {
        final daysSinceInstall = DateTime.now().difference(installDateTime).inDays;
        if (daysSinceInstall <= 7) return true; // 7 kun ichida bepul
      }
    }

    // Litsenziya kaliti orqali Premium
    if (_premiumExpiry.isEmpty) return false;
    final expiryDate = DateTime.tryParse(_premiumExpiry);
    if (expiryDate == null) return false;
    return DateTime.now().isBefore(expiryDate);
  }

  int get trialDaysLeft {
    if (_installDate.isEmpty) return 0;
    final installDateTime = DateTime.tryParse(_installDate);
    if (installDateTime == null) return 0;
    final daysSinceInstall = DateTime.now().difference(installDateTime).inDays;
    final left = 7 - daysSinceInstall;
    return left > 0 ? left : 0;
  }

  String _generateDeviceId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final part1 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    final part2 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return 'SRGK-$part1-$part2';
  }


  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _language = prefs.getString('language') ?? 'uz';
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    
    _deviceId = prefs.getString('device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await prefs.setString('device_id', _deviceId);
    }
    
    _installDate = prefs.getString('install_date') ?? '';
    if (_installDate.isEmpty) {
      _installDate = DateTime.now().toIso8601String();
      await prefs.setString('install_date', _installDate);
    }

    _premiumExpiry = prefs.getString('premium_expiry') ?? '';
    
    notifyListeners();

  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> toggleVibration(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
    notifyListeners();
  }

  bool _verifyRsaSignature(String message, String signatureBase64) {
    try {
      final sigBytes = base64Decode(signatureBase64);
      final n = BigInt.parse('22586584884082431343545952398410511061286839290030759966521927002716395585790093178315043541318673775524204058081491827121472539349481811691576989064552133480901293163515147671094272962710041543089188585558827486862734674722142355132261090508248052279139496384459093632808406326369471862576134128418936715347509350302084485882822283672017289321800462862784402846336375091063385198870097396474536424513002538690868932579446312691583315753647236667075441774564063660840964296841217330507788025298833549029153222460731022253608983669953168282943745742828629485963701899371709041413950572855850283955437556476222565756453');
      final e = BigInt.from(65537);
      
      var s = BigInt.from(0);
      for (var b in sigBytes) {
        s = (s << 8) + BigInt.from(b);
      }
      
      final m = s.modPow(e, n);
      
      final decryptedBytes = List<int>.filled(256, 0);
      var temp = m;
      for (var i = 255; i >= 0; i--) {
        decryptedBytes[i] = (temp & BigInt.from(0xff)).toInt();
        temp = temp >> 8;
      }
      
      if (decryptedBytes[0] != 0x00 || decryptedBytes[1] != 0x01) {
        return false;
      }
      
      var idx = 2;
      while (idx < decryptedBytes.length && decryptedBytes[idx] == 0xff) {
        idx++;
      }
      
      if (idx >= decryptedBytes.length || decryptedBytes[idx] != 0x00) {
        return false;
      }
      idx++;
      
      final digestInfo = decryptedBytes.sublist(idx);
      final expectedPrefix = [0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20];
      if (digestInfo.length != expectedPrefix.length + 32) {
        return false;
      }
      
      for (var i = 0; i < expectedPrefix.length; i++) {
        if (digestInfo[i] != expectedPrefix[i]) return false;
      }
      
      final hash = digestInfo.sublist(expectedPrefix.length);
      final msgBytes = utf8.encode(message);
      final msgHash = sha256.convert(msgBytes).bytes;
      
      for (var i = 0; i < 32; i++) {
        if (hash[i] != msgHash[i]) return false;
      }
      
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyAndActivatePremium(String key) async {
    try {
      final decoded = utf8.decode(base64Decode(key));
      final parts = decoded.split('|');
      if (parts.length != 2) return false;
      
      final signature = parts[0];
      final expiryStr = parts[1];
      
      final msg = '$_deviceId|$expiryStr';
      var isSignatureValid = _verifyRsaSignature(msg, signature);
      
      // Fallback to legacy HMAC verification
      if (!isSignatureValid) {
        const secretKey = 'SERGAKxavfsizlik2026TAFUxusniddinSecret!';
        final hmac = Hmac(sha256, utf8.encode(secretKey));
        final digest = hmac.convert(utf8.encode(_deviceId + expiryStr));
        final expectedSignature = base64Encode(digest.bytes);
        if (signature == expectedSignature) {
          isSignatureValid = true;
        }
      }
      
      if (isSignatureValid) {
        final expiryDate = DateTime.tryParse(expiryStr);
        if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
          _premiumExpiry = expiryStr;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('premium_expiry', _premiumExpiry);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
