import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class FirebaseService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addOrUpdateNote(NoteModel note) async {
    await _firestore.collection('notes').doc(note.id).set({
      ...note.toMap(),
    });
  }

  Future<List<NoteModel>> fetchNotes() async {
    final snapshot = await _firestore.collection('notes').get();

    return snapshot.docs
        .map((doc) => NoteModel.fromMap(doc.data()))
        .toList();
  }
}
