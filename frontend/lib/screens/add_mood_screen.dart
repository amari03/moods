import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../api/api_service.dart';
import 'package:flutter/foundation.dart' as foundation;

class AddMoodScreen extends StatefulWidget {
  // Optional: If provided, we are in "Edit Mode"
  final Map<String, dynamic>? moodToEdit; 

  const AddMoodScreen({super.key, this.moodToEdit});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  Color _selectedColor = Colors.deepPurple;
  String _selectedEmoji = "🙂";
  bool _isSubmitting = false;
  bool _showEmojiPicker = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Check if we are editing existing data
    if (widget.moodToEdit != null) {
      _isEditMode = true;
      final m = widget.moodToEdit!;
      _titleController.text = m['title'] ?? "";
      _descController.text = m['content'] ?? "";
      _selectedEmoji = m['emoji'] ?? "🙂";
      
      // Parse Color
      if (m['color'] != null) {
        try {
          _selectedColor = Color(int.parse(m['color']));
        } catch (_) {}
      }
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        // UPDATE EXISTING
        await ApiService.updateMood(
          id: widget.moodToEdit!['id'], // We need the ID to update
          title: _titleController.text,
          description: _descController.text,
          emoji: _selectedEmoji,
          colorValue: _selectedColor.toARGB32(),
        );
      } else {
        // CREATE NEW
        await ApiService.createMood(
          title: _titleController.text,
          description: _descController.text,
          emoji: _selectedEmoji,
          colorValue: _selectedColor.toARGB32(),
        );
      }
      
      if (mounted) {
        context.pop(); // Go back to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Mood Note" : "Add Mood Note"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), 
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                           FocusScope.of(context).unfocus();
                           setState(() => _showEmojiPicker = !_showEmojiPicker);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(_selectedEmoji, style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _pickColor,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                          ),
                          child: const Icon(Icons.palette, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(_isEditMode ? "Update your vibe!" : "Pick your vibe!", 
                           style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: "How are you feeling?", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15)),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(15),
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : Text(_isEditMode ? "Update Note" : "Save Note"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          if (_showEmojiPicker && !isKeyboardVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _selectedEmoji = emoji.emoji;
                    _showEmojiPicker = false;
                  });
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}