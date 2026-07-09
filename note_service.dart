import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _notesRef => _firestore.collection('notes');

  // Stream semua notes user yang login
  Stream<List<NoteModel>> getNotes() {
    return _notesRef
        .where('userId', isEqualTo: _userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
  }

  // Search notes
  Stream<List<NoteModel>> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _notesRef
        .where('userId', isEqualTo: _userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .where((note) =>
                note.title.toLowerCase().contains(lowerQuery) ||
                note.content.toLowerCase().contains(lowerQuery))
            .toList());
  }

  // Tambah note
  Future<void> addNote(String title, String content) async {
    final now = DateTime.now();
    await _notesRef.add({
      'userId': _userId,
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // Edit note
  Future<void> updateNote(String noteId, String title, String content) async {
    await _notesRef.doc(noteId).update({
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Hapus note
  Future<void> deleteNote(String noteId) async {
    await _notesRef.doc(noteId).delete();
  }
}