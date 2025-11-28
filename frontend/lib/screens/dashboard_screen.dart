import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = "Friend";
  
  // Search & Filter State
  String _searchQuery = ""; 
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = "newest"; 
  
  late Future<String> _quoteFuture;
  late Future<List<dynamic>> _moodsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Friend";
    });
  }

  void _refreshData() {
    setState(() {
      _quoteFuture = ApiService.getQuote();
      _moodsFuture = ApiService.getMoods();
    });
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.deepPurple;
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort By", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildSortOption(Icons.access_time_filled, "Newest First", 'newest'),
              _buildSortOption(Icons.history, "Oldest First", 'oldest'),
              _buildSortOption(Icons.sort_by_alpha, "Title (A-Z)", 'a-z'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(IconData icon, String title, String value) {
    final isSelected = _sortOption == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.deepPurple : Colors.black87
          )
        ),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
        onTap: () {
          setState(() => _sortOption = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMoodDetails(Map<String, dynamic> mood) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final color = _parseColor(mood['color']);
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(mood['emoji'] ?? "🙂", style: const TextStyle(fontSize: 35)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  mood['title'] ?? "Mood",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text(
                      mood['created_at'] ?? '', 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    mood['content'] ?? "No description", 
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text("Delete", style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: dialogContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Note?"),
                          content: const Text("This cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ApiService.deleteMood(mood['id']);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) _refreshData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text("Edit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await context.push('/add-mood', extra: mood);
                      if (mounted) _refreshData();
                    },
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      await context.push('/add-mood');
      if (mounted) _refreshData();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(), 
      Container(), // Placeholder for Add button (handled by onTap)
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      floatingActionButton: (_selectedIndex == 0) 
          ? FloatingActionButton(
              onPressed: () async {
                 await context.push('/add-mood');
                 if (mounted) _refreshData();
              },
              backgroundColor: Colors.deepPurple,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ) 
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 32), label: 'Add'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 1. HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      "$_userName! 👋",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2), width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // 2. QUOTE
            FutureBuilder<String>(
              future: _quoteFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(color: Colors.deepPurple, backgroundColor: Colors.white);
                }
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5)
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.format_quote, color: Colors.white70, size: 30),
                      Text(
                        snapshot.data ?? 'Stay positive!',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16, color: Colors.white, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            
            // 3. MOOD CONTENT
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _moodsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } 
                  
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final allMoods = snapshot.data!;
                  
                  final filteredMoods = allMoods.where((m) {
                    final title = (m['title'] ?? "").toString().toLowerCase();
                    final content = (m['content'] ?? "").toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return title.contains(query) || content.contains(query);
                  }).toList();

                  filteredMoods.sort((a, b) {
                    switch (_sortOption) {
                      case 'oldest':
                        return (a['created_at'] ?? '').compareTo(b['created_at'] ?? '');
                      case 'a-z':
                        return (a['title'] ?? '').compareTo(b['title'] ?? '');
                      case 'newest':
                      default:
                        return (b['created_at'] ?? '').compareTo(a['created_at'] ?? '');
                    }
                  });

                  return Column(
                    children: [
                      // --- SEARCH & FILTER BAR ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
                                ]
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                                decoration: InputDecoration(
                                  hintText: "Search moods...",
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = "");
                                        },
                                      ) 
                                    : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: _showFilterModal,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
                                ]
                              ),
                              child: const Icon(Icons.filter_list_rounded, color: Colors.deepPurple),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- THE LIST ---
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredMoods.length,
                          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                          itemBuilder: (context, index) {
                            final mood = filteredMoods[index];
                            final color = _parseColor(mood['color']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
                                ],
                                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _showMoodDetails(mood),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            mood['emoji'] ?? "🙂", 
                                            style: const TextStyle(fontSize: 32)
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mood['title'] ?? "Mood", 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                mood['content'] ?? "",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                mood['created_at'] ?? '',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.note_alt_outlined, size: 60, color: Colors.deepPurple.shade200),
          ),
          const SizedBox(height: 20),
          const Text("No mood notes yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
               await context.push('/add-mood');
               if (mounted) _refreshData();
            },
            icon: const Icon(Icons.add),
            label: const Text("Create your first note"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
          )
        ],
      ),
    );
  }
}