import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../repositories/notes_repository.dart';
import '../models/note_model.dart';

class NotesProvider extends ChangeNotifier {
  final NotesRepository repository = NotesRepository();

  List<NoteModel> notes = [];
  int queueSize = 0;
  int successCount = 0;
  int failureCount = 0;

  NotesProvider() {
    _listenToQueueChanges();
  }

  // ---------------- LISTEN TO QUEUE CHANGES ----------------

  void _listenToQueueChanges() {
    Hive.box('sync_queue').watch().listen((event) {
      _refreshState();
    });
  }

  void _refreshState() {
    notes = repository.getNotes();
    queueSize = repository.getQueueSize();
    successCount = repository.getSuccessCount();
    failureCount = repository.getFailureCount();
    notifyListeners();
  }

  // ---------------- LOAD NOTES ----------------

  Future<void> loadNotes() async {
    _refreshState();

    await repository.loadFromServer();

    _refreshState();
  }

  // ---------------- ADD NOTE ----------------

  Future<void> addNote(String content) async {
    if (content.isEmpty) return;

    await repository.addNote(content);

    _refreshState();
  }

  // ---------------- UPDATE NOTE ----------------

  Future<void> updateNote(String id, String content) async {
    if (content.isEmpty) return;

    await repository.updateNote(id, content);

    _refreshState();
  }
}
