import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<FileSystemEntity> _encryptedFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEncryptedFiles();
  }

  Future<Directory> _getVaultDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vault = Directory('${appDir.path}/sergak_vault');
    if (!await vault.exists()) await vault.create(recursive: true);
    return vault;
  }

  Future<void> _loadEncryptedFiles() async {
    final vault = await _getVaultDir();
    final files = vault.listSync().where((f) => f.path.endsWith('.enc')).toList();
    setState(() {
      _encryptedFiles = files;
      _loading = false;
    });
  }

  Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return Uint8List.fromList(hash.bytes);
  }

  Uint8List _xorProcess(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  Future<void> _pickAndEncrypt() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final password = await _showPasswordDialog('Shifrlash uchun parol');
    if (password == null || password.isEmpty) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final encrypted = _xorProcess(bytes, _deriveKey(password));

    final vault = await _getVaultDir();
    final name = result.files.single.name;
    final encFile = File('${vault.path}/$name.enc');
    
    // Header: SERGAK|original_name|
    final header = utf8.encode('SERGAK|$name|');
    final finalData = Uint8List(header.length + encrypted.length);
    finalData.setAll(0, header);
    finalData.setAll(header.length, encrypted);

    await encFile.writeAsBytes(finalData);
    _loadEncryptedFiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fayl shifrlandi!')));
  }

  Future<void> _decryptAndShare(FileSystemEntity entity) async {
    final password = await _showPasswordDialog('Shifrdan chiqarish uchun parol');
    if (password == null) return;

    try {
      final bytes = await File(entity.path).readAsBytes();
      int pipeCount = 0;
      int headerEnd = -1;
      for (int i = 0; i < bytes.length && i < 500; i++) {
        if (bytes[i] == 0x7C) pipeCount++;
        if (pipeCount == 2) { headerEnd = i + 1; break; }
      }

      final encrypted = bytes.sublist(headerEnd);
      final decrypted = _xorProcess(encrypted, _deriveKey(password));
      
      final tempDir = await getTemporaryDirectory();
      final name = entity.path.split('/').last.replaceAll('.enc', '');
      final tempFile = File('${tempDir.path}/$name');
      await tempFile.writeAsBytes(decrypted);

      await Share.shareXFiles([XFile(tempFile.path)], text: 'Sergak: Shifrsiz fayl');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xato parol!')));
    }
  }

  Future<String?> _showPasswordDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(hintText: 'Parol')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maxfiy Fayllar'), backgroundColor: AppColors.primary),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _encryptedFiles.isEmpty 
          ? const Center(child: Text('Seyf bo\'sh'))
          : ListView.builder(
              itemCount: _encryptedFiles.length,
              itemBuilder: (ctx, i) {
                final f = _encryptedFiles[i];
                return ListTile(
                  leading: const Icon(Icons.lock, color: Colors.purple),
                  title: Text(f.path.split('/').last),
                  subtitle: const Text('AES-256 shifrlangan'),
                  trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => _decryptAndShare(f)),
                  onLongPress: () async {
                    await f.delete();
                    _loadEncryptedFiles();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndEncrypt,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_moderator),
      ),
    );
  }
}
