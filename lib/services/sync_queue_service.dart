import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sync_action_model.dart';
import 'local_storage_service.dart';
import 'firebase_service.dart';
import '../models/note_model.dart';

class SyncQueueService {
  final LocalStorageService localStorage;
  final FirebaseService firebaseService;

  int successCount = 0;
  int failureCount = 0;

  bool _isProcessing = false;

  SyncQueueService({
    required this.localStorage,
    required this.firebaseService,
  }) {
    print("🟢 SyncQueueService initialized");

    // ✅ Load persisted metrics
    successCount = localStorage.getSuccessCount();
    failureCount = localStorage.getFailureCount();

    _listenToConnectivity();
    processQueue();
  }


  // ---------------- CONNECTIVITY LISTENER ----------------

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        print("🌐 Internet detected. Processing queue...");
        processQueue();
      }
    });
  }

  // ---------------- PROCESS QUEUE ----------------

  Future<void> processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      print("🚫 No internet. Skipping sync.");
      _isProcessing = false;
      return;
    }
    final queue = localStorage.getQueue()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));


    print("🔄 Starting sync. Queue size: ${queue.length}");

    for (var action in queue) {
      try {
        await _executeAction(action);
        await localStorage.removeFromQueue(action.actionId);

        successCount++;
        await localStorage.saveSuccessCount(successCount);

        print("✅ Synced action: ${action.actionId}");

      } catch (e) {
        failureCount++;
        await localStorage.saveFailureCount(failureCount);

        print("❌ Failed action: ${action.actionId}");


        // Retry once with backoff
        if (action.retryCount < 1) {
          await Future.delayed(const Duration(seconds: 2));

          final retryAction = SyncAction(
            actionId: action.actionId,
            type: action.type,
            payload: action.payload,
            retryCount: action.retryCount + 1,
          );

          await localStorage.addToQueue(retryAction);
        }
      }
    }

    print("📊 Sync Done. Success: $successCount | Fail: $failureCount");

    _isProcessing = false;
  }

  // ---------------- EXECUTE ACTION ----------------

  Future<void> _executeAction(SyncAction action) async {
    final note = NoteModel.fromMap(action.payload);

    // 🔥 Simulate transient failure
    if (note.content.toLowerCase().contains("fail") &&
        action.retryCount == 0) {
      print("⚠ Simulated failure for ${note.id}");
      throw Exception("Simulated transient failure");
    }

    if (action.type == "add_note") {
      await firebaseService.addOrUpdateNote(note);
    }

    if (action.type == "update_note") {
      await firebaseService.addOrUpdateNote(note);
    }
    print("Uploading note id: ${note.id}, content: ${note.content}");

  }
}
