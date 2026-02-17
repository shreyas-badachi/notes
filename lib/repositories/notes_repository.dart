import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/sync_action_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/sync_queue_service.dart';

class NotesRepository {
  final LocalStorageService localStorage;
  final FirebaseService firebaseService;
  late final SyncQueueService syncService;

  DateTime? lastFetchTime; // 🔥 TTL support

  NotesRepository()
      : localStorage = LocalStorageService(),
        firebaseService = FirebaseService() {
    syncService = SyncQueueService(
      localStorage: localStorage,
      firebaseService: firebaseService,
    );
  }

  // ---------------- GET NOTES ----------------

  List<NoteModel> getNotes() {
    return localStorage.getNotes();
  }

  // ---------------- TTL SERVER LOAD ----------------

  Future<void> loadFromServer() async {
    // TTL: 5 minutes
    if (lastFetchTime != null &&
        DateTime.now().difference(lastFetchTime!) <
            const Duration(minutes: 5)) {
      print("⏳ Using cached data (TTL active)");
      return;
    }

    final notes = await firebaseService.fetchNotes();

    for (var note in notes) {
      await localStorage.saveNote(note);
    }

    lastFetchTime = DateTime.now();
  }

  // ---------------- ADD NOTE ----------------

  Future<void> addNote(String content) async {
    final id = const Uuid().v4();

    final note = NoteModel(
      id: id,
      content: content,
      updatedAt: DateTime.now(),
    );

    // 1️⃣ Save locally first
    await localStorage.saveNote(note);

    // 2️⃣ Add to queue
    final action = SyncAction(
      actionId: id, // idempotency key
      type: "add_note",
      payload: note.toMap(),
    );

    await localStorage.addToQueue(action);

    // 3️⃣ Attempt sync
    await syncService.processQueue();
  }

  // ---------------- UPDATE NOTE ----------------

  Future<void> updateNote(String id, String content) async {
    final note = NoteModel(
      id: id,
      content: content,
      updatedAt: DateTime.now(),
    );

    await localStorage.saveNote(note);

    final action = SyncAction(
      actionId: const Uuid().v4(),
      type: "update_note",
      payload: note.toMap(),
    );

    await localStorage.addToQueue(action);

    await syncService.processQueue();
  }

  // ---------------- COUNTERS ----------------

  int getQueueSize() => localStorage.getQueueSize();
  int getSuccessCount() => syncService.successCount;
  int getFailureCount() => syncService.failureCount;
}
