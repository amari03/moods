import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../api/api_service.dart';
import 'package:flutter/foundation.dart' as foundation;

class AddMoodScreen extends StatefulWidget {
  final Map<String, dynamic>? moodToEdit; 

  const AddMoodScreen({super.key, this.moodToEdit});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  Color _selectedColor = const Color(0xFF673AB7); // Deep Purple default
  String _selectedEmoji = "🙂";
  bool _isSubmitting = false;
  bool _showEmojiPicker = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.moodToEdit != null) {
      _isEditMode = true;
      final m = widget.moodToEdit!;
      _titleController.text = m['title'] ?? "";
      _descController.text = m['content'] ?? "";
      _selectedEmoji = m['emoji'] ?? "🙂";
      
      if (m['color'] != null) {
        try {
          // Fix for color parsing if needed
          _selectedColor = Color(int.parse(m['color']));
        } catch (_) {}
      }
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pick your vibe color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            enableAlpha: false,
            displayThumbColor: true,
            hexInputBar: false,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Give your mood a title!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await ApiService.updateMood(
          id: widget.moodToEdit!['id'],
          title: _titleController.text,
          description: _descController.text,
          emoji: _selectedEmoji,
          // NEW FLUTTER FIX: use .toARGB32()
          colorValue: _selectedColor.toARGB32(),
        );
      } else {
        await ApiService.createMood(
          title: _titleController.text,
          description: _descController.text,
          emoji: _selectedEmoji,
          // NEW FLUTTER FIX: use .toARGB32()
          colorValue: _selectedColor.toARGB32(),
        );
      }
      
      if (mounted) {
        context.pop(); 
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
    
    // Determine if the selected color is too light (so we can change text color)
    final isLightColor = _selectedColor.computeLuminance() > 0.5;
    final textColor = isLightColor ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Dynamic Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // NEW FLUTTER FIX: use .withValues(alpha: ...)
                  _selectedColor.withValues(alpha: 0.3),
                  Colors.white,
                ],
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        color: Colors.black87,
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        _isEditMode ? "Edit Mood" : "New Mood",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      // Invisible icon to balance the row
                      const SizedBox(width: 48), 
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        
                        // --- HERO SECTION: EMOJI & COLOR ---
                        Center(
                          child: GestureDetector(
                            onTap: () {
                               FocusScope.of(context).unfocus();
                               setState(() => _showEmojiPicker = !_showEmojiPicker);
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                // The Emoji
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _selectedColor.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 70)),
                                  ),
                                ),
                                
                                // The Color Picker Badge
                                GestureDetector(
                                  onTap: _pickColor,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                                    ),
                                    child: Icon(Icons.palette, color: textColor, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        Text(
                          "Tap emoji or color to change",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),

                        const SizedBox(height: 40),

                        // --- TITLE INPUT ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Title (e.g. Morning Coffee)",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.all(20),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.title, color: Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- DESCRIPTION INPUT ---
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                          ),
                          child: TextField(
                            controller: _descController,
                            maxLines: null, // Allow unlimited lines
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "How are you feeling right now? \nPour your heart out...",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.all(20),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- SAVE BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedColor,
                              foregroundColor: textColor, // dynamic text color
                              elevation: 5,
                              shadowColor: _selectedColor.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSubmitting 
                              ? CircularProgressIndicator(color: textColor) 
                              : Text(
                                  _isEditMode ? "Update Note" : "Save Note",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                          ),
                        ),
                        
                        // Extra spacing for scroll
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Emoji Picker (Slide up from bottom)
          if (_showEmojiPicker && !isKeyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _selectedEmoji = emoji.emoji;
                      _showEmojiPicker = false;
                    });
                  },
                  config: Config(
                    height: 250,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}