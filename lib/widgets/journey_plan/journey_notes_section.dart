import 'package:flutter/material.dart';

class JourneyNotesSection extends StatefulWidget {
  final String? initialNotes;
  final Function(String)? onNotesChanged;
  final bool isEditing;
  final bool isSaving;

  const JourneyNotesSection({
    super.key,
    this.initialNotes,
    this.onNotesChanged,
    this.isEditing = false,
    this.isSaving = false,
  });

  @override
  State<JourneyNotesSection> createState() => _JourneyNotesSectionState();
}

class _JourneyNotesSectionState extends State<JourneyNotesSection> {
  late TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _isEditing = widget.isEditing;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.note,
              size: 12,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Notes:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (!_isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_isEditing) ...[
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes about this journey...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(8),
              isDense: true,
            ),
            onChanged: widget.onNotesChanged,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditing = false;
                          _notesController.text = widget.initialNotes ?? '';
                        });
                      },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.isSaving
                    ? null
                    : () {
                        widget.onNotesChanged?.call(_notesController.text);
                        setState(() {
                          _isEditing = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontSize: 10),
                      ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _notesController.text.isEmpty
                  ? 'No notes added'
                  : _notesController.text,
              style: TextStyle(
                fontSize: 11,
                color: _notesController.text.isEmpty
                    ? Colors.grey.shade500
                    : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
