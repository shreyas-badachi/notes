import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../models/sync_action_model.dart';

class LocalStorageService {
  final Box notesBox = Hive.box('notes');
  final Box queueBox = Hive.box('sync_queue');
  final Box metricsBox = Hive.box('metrics'); // ✅ Correct box

  // -------- NOTES --------

  List<NoteModel> getNotes() {
    return notesBox.values
        .map((e) => NoteModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveNote(NoteModel note) async {
    await notesBox.put(note.id, note.toMap());
  }

  // -------- SYNC QUEUE --------

  List<SyncAction> getQueue() {
    return queueBox.values
        .map((e) => SyncAction.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addToQueue(SyncAction action) async {
    await queueBox.put(action.actionId, action.toMap());
  }

  Future<void> removeFromQueue(String actionId) async {
    await queueBox.delete(actionId);
  }

  int getQueueSize() => queueBox.length;

  // -------- METRICS --------

  int getSuccessCount() =>
      metricsBox.get('success', defaultValue: 0);

  int getFailureCount() =>
      metricsBox.get('failure', defaultValue: 0);

  Future<void> saveSuccessCount(int value) async {
    await metricsBox.put('success', value);
  }

  Future<void> saveFailureCount(int value) async {
    await metricsBox.put('failure', value);
  }
}
