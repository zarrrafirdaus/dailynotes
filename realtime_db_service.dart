import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service ini mendemonstrasikan akses REST API murni ke
/// Firebase Realtime Database menggunakan HTTP method
/// GET, POST, PUT, PATCH, DELETE
class RealtimeDbService {
  // Ganti sesuai URL Realtime Database project kamu
  static const String _baseUrl =
      'https://dailynotes-rara-default-rtdb.asia-southeast1.firebasedatabase.app';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil ID token user yang login, dipakai sebagai
  /// autentikasi (query param ?auth=) pada setiap request REST
  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');
    return await user.getIdToken() ?? '';
  }

  String get _uid => _auth.currentUser!.uid;

  /// GET — mengambil semua data backup notes milik user
  /// Endpoint: /notes_backup/{uid}.json
  Future<Map<String, dynamic>> getBackupNotes() async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/notes_backup/$_uid.json?auth=$token');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: token tidak valid');
    } else if (response.statusCode == 404) {
      throw Exception('Data tidak ditemukan');
    } else {
      throw Exception('Gagal ambil data: ${response.statusCode}');
    }
  }

  /// POST — menambah note baru ke backup (id di-generate otomatis
  /// oleh Firebase, mirip auto-increment)
  /// Endpoint: /notes_backup/{uid}.json
  Future<String> addBackupNote(String title, String content) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/notes_backup/$_uid.json?auth=$token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['name']; // id note baru yang di-generate
    } else {
      throw Exception('Gagal tambah data: ${response.statusCode}');
    }
  }

  /// PUT — mengganti SELURUH isi note (title + content ke-replace semua)
  /// Endpoint: /notes_backup/{uid}/{noteId}.json
  Future<void> replaceBackupNote(
      String noteId, String title, String content) async {
    final token = await _getToken();
    final url =
        Uri.parse('$_baseUrl/notes_backup/$_uid/$noteId.json?auth=$token');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update data: ${response.statusCode}');
    }
  }

  /// PATCH — mengubah SEBAGIAN field saja, misal title doang
  /// tanpa menyentuh content
  /// Endpoint: /notes_backup/{uid}/{noteId}.json
  Future<void> updateBackupNoteTitle(String noteId, String newTitle) async {
    final token = await _getToken();
    final url =
        Uri.parse('$_baseUrl/notes_backup/$_uid/$noteId.json?auth=$token');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': newTitle}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update title: ${response.statusCode}');
    }
  }

  /// DELETE — menghapus satu note dari backup
  /// Endpoint: /notes_backup/{uid}/{noteId}.json
  Future<void> deleteBackupNote(String noteId) async {
    final token = await _getToken();
    final url =
        Uri.parse('$_baseUrl/notes_backup/$_uid/$noteId.json?auth=$token');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Gagal hapus data: ${response.statusCode}');
    }
  }
}