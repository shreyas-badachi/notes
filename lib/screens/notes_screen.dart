import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline First Notes"),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await Hive.box('notes').clear();
              await Hive.box('sync_queue').clear();
              await Hive.box('metrics').clear();

              print("🗑 Hive Cleared");
            },
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Queue: ${provider.queueSize}"),
                Text("✔ ${provider.successCount} | ❌ ${provider.failureCount}",
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: provider.notes.length,
              itemBuilder: (_, index) {
                final note = provider.notes[index];
                return ListTile(
                  onTap: () async {
                    final newText = await _showEditDialog(note.content);
                    if (newText != null) {
                      provider.updateNote(note.id, newText);
                    }
                  },

                  title: Text(note.content),
                  subtitle: Text(note.updatedAt.toString()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    const InputDecoration(hintText: "Enter note"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    provider.addNote(_controller.text);
                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Future<String?> _showEditDialog(String oldText) {
    final controller = TextEditingController(text: oldText);

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Note"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

}
