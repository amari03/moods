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
      backgroundColor: const Color(0xFFF8F9FA), // Soft off-white background
      appBar: AppBar(
        title: const Text(
          "Insights",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOTAL COUNT CARD
                _buildTotalCard(totalCount),
                const SizedBox(height: 20),

                // 2. TOP EMOJIS CARD
                const Text("Top Vibes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                _buildTopEmojisCard(topEmojis),
                const SizedBox(height: 25),

                // 3. COLOR PALETTE CARD
                const Text("Mood Palette", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                _buildColorPaletteCard(colorStats, totalCount),
                
                const SizedBox(height: 40), // Bottom padding
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
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 60, color: Colors.deepPurple.shade200),
          ),
          const SizedBox(height: 20),
          Text(
            "No stats available yet",
            style: TextStyle(color: Colors.grey.shade800, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Log some moods to see your insights!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Entries", 
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 5),
              Text(
                "$count", 
                style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildTopEmojisCard(List<MapEntry<String, int>> topEmojis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: topEmojis.map((entry) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(entry.key, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 10),
              Text(
                "${entry.value} times", 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPaletteCard(Map<String, int> colorStats, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Progress Bar Stack
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 35,
              child: Row(
                children: colorStats.entries.map((entry) {
                  final color = _parseColor(entry.key);
                  final percentage = entry.value / total;
                  return Expanded(
                    flex: (percentage * 100).toInt(),
                    child: Container(
                      color: color,
                      child: Center(
                        // Only show % if it fits
                        child: percentage > 0.1 
                          ? Text(
                              "${(percentage * 100).toInt()}%", 
                              style: TextStyle(
                                color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold
                              )
                            ) 
                          : const SizedBox(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text(
                "Your mood colors distribution", 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)
              ),
            ],
          ),
        ],
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