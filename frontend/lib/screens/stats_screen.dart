import 'package:flutter/material.dart';
import '../api/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<dynamic>> _moodsFuture;

  @override
  void initState() {
    super.initState();
    _moodsFuture = ApiService.getMoods();
  }

  // Helper to parse color string
  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.deepPurple;
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Statistics"),
        centerTitle: false,
        automaticallyImplyLeading: false, 
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _moodsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStats();
          }

          final moods = snapshot.data!;
          final totalCount = moods.length;
          final topEmojis = _getTopEmojis(moods);
          final colorStats = _getColorStats(moods);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. TOTAL COUNT CARD
                _buildTotalCard(totalCount),
                const SizedBox(height: 20),

                // 2. TOP EMOJIS CARD
                _buildTopEmojisCard(topEmojis),
                const SizedBox(height: 20),

                // 3. COLOR PALETTE CARD
                _buildColorPaletteCard(colorStats, totalCount),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStats() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Log some moods to see your stats!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // FIX: Use .withValues(alpha: ...) instead of .withOpacity(...)
            color: Colors.deepPurple.withValues(alpha: 0.3), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Total Moods Logged", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          Text(
            "$count", 
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmojisCard(List<MapEntry<String, int>> topEmojis) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Top Vibes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: topEmojis.map((entry) {
                return Column(
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 40)), // The Emoji
                    const SizedBox(height: 5),
                    Text("${entry.value} times", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteCard(Map<String, int> colorStats, int total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Mood Palette", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            // Custom Progress Bar Stack
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: colorStats.entries.map((entry) {
                    final color = _parseColor(entry.key);
                    final percentage = entry.value / total;
                    return Expanded(
                      flex: (percentage * 100).toInt(),
                      child: Container(color: color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text("Based on the colors you pick for your notes.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // --- LOGIC HELPERS ---

  List<MapEntry<String, int>> _getTopEmojis(List<dynamic> moods) {
    final map = <String, int>{};
    for (var m in moods) {
      final emoji = m['emoji'] ?? "❓";
      map[emoji] = (map[emoji] ?? 0) + 1;
    }
    // Sort descending
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Take top 3
    return sortedEntries.take(3).toList();
  }

  Map<String, int> _getColorStats(List<dynamic> moods) {
    final map = <String, int>{};
    for (var m in moods) {
      final color = m['color'] ?? "";
      if (color.isNotEmpty) {
        map[color] = (map[color] ?? 0) + 1;
      }
    }
    return map;
  }
}