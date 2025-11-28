import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';

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
  String _sortOption = "newest"; // Options: 'newest', 'oldest', 'a-z'
  
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort By", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text("Newest First"),
                trailing: _sortOption == 'newest' ? const Icon(Icons.check, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() => _sortOption = 'newest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Oldest First"),
                trailing: _sortOption == 'oldest' ? const Icon(Icons.check, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() => _sortOption = 'oldest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("Title (A-Z)"),
                trailing: _sortOption == 'a-z' ? const Icon(Icons.check, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() => _sortOption = 'a-z');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SHOW DETAILS POP-UP ---
  void _showMoodDetails(Map<String, dynamic> mood) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final color = _parseColor(mood['color']);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(mood['emoji'] ?? "🙂", style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
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
                Text("Created: ${mood['created_at']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 10),
                Divider(color: color.withValues(alpha: 0.5), thickness: 2),
                const SizedBox(height: 10),
                Text(mood['content'] ?? "No description", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: [
            // DELETE BUTTON
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Delete", style: TextStyle(color: Colors.red)),
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
                  
                  // FIX 1: Check if dialog is still mounted before popping
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext); 
                  }
                  // FIX 2: Check if State is still mounted before refreshing
                  if (mounted) {
                    _refreshData();
                  }
                }
              },
            ),
            // EDIT BUTTON
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dialogContext); // Sync pop is fine
                await context.push('/add-mood', extra: mood);
                
                if (mounted) {
                  _refreshData();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      await context.push('/add-mood');
      if (mounted) {
        _refreshData();
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(), 
      Container(),    
      const Center(child: Text("Stats Page (Coming Soon)")),
      _buildSettingsTab(),
    ];

    return Scaffold(
      floatingActionButton: (_selectedIndex == 0) 
          ? FloatingActionButton(
              onPressed: () async {
                 await context.push('/add-mood');
                 if (mounted) {
                   _refreshData();
                 }
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
            ) 
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back, $_userName! 🙂",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            FutureBuilder<String>(
              future: _quoteFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                return Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple.shade100),
                  ),
                  child: Text(
                    snapshot.data ?? 'Stay positive!',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                              decoration: InputDecoration(
                                hintText: "Search your moods...",
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = "");
                                      },
                                    ) 
                                  : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list, color: Colors.deepPurple),
                              onPressed: _showFilterModal,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),

                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredMoods.length,
                          itemBuilder: (context, index) {
                            final mood = filteredMoods[index];
                            final color = _parseColor(mood['color']);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: color.withValues(alpha: 0.5), 
                                  width: 2
                                )
                              ),
                              child: ListTile(
                                onTap: () => _showMoodDetails(mood),
                                contentPadding: const EdgeInsets.all(15),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    mood['emoji'] ?? "🙂", 
                                    style: const TextStyle(fontSize: 28)
                                  ),
                                ),
                                title: Text(
                                  mood['title'] ?? "Mood", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      mood['content'] ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      mood['created_at'] ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
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
          Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("No mood notes yet.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
               await context.push('/add-mood');
               if (mounted) {
                 _refreshData();
               }
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Mood Note"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) context.go('/'); 
        },
        child: const Text("Logout"),
      ),
    );
  }
}