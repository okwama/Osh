import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditNotesDialog extends StatelessWidget {
  final String? initialNotes;
  final Function(String) onSave;

  const EditNotesDialog({
    super.key,
    this.initialNotes,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController notesController = TextEditingController(
      text: initialNotes ?? '',
    );

    return AlertDialog(
      title: const Text('Edit Notes'),
      content: TextField(
        controller: notesController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter notes about this journey plan...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            onSave(notesController.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  static void show({
    String? initialNotes,
    required Function(String) onSave,
  }) {
    Get.dialog(
      EditNotesDialog(
        initialNotes: initialNotes,
        onSave: onSave,
      ),
    );
  }
} 