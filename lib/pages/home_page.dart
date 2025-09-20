import 'package:flutter/material.dart';
import 'package:lapabricks/pages/add_labour_page.dart';
import 'package:lapabricks/pages/labour_detail_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LabourStore>();
    const Color cream = Color(0xFFFFF6E5);
    const Color lightOrange = Color(0xFFFFB74D);
    const Color orangeAccent = Color(0xFFFF9800);

    if (!store.loaded) {
      return Scaffold(
        backgroundColor: cream,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(orangeAccent),
          ),
        ),
      );
    }

    final labours = store.labours.where((labour) =>
      _searchQuery.isEmpty ||
      labour.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: orangeAccent,
        titleSpacing: 0,
        title: _showSearchBar
            ? Container(
                height: 40,
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    hintText: "Search labour...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: orangeAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: _toggleSearchBar,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              )
            : const Text('Lapa Bricks'),
        titleTextStyle: const TextStyle(color: Colors.white),
        actions: [
          if (!_showSearchBar)
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _toggleSearchBar,
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 550
              ? constraints.maxWidth * 0.98
              : constraints.maxWidth < 1000
                  ? 540
                  : 720;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: labours.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', height: 90),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                            ? 'No labours yet!'
                            : 'No labours match your search.',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                            ? 'Tap the Add button to start.'
                            : 'Try changing your search.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: labours.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final labour = labours[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LabourDetailPage(labourId: labour.id),
                            ),
                          ),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [cream, lightOrange.withOpacity(0.12)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: orangeAccent.withOpacity(0.14),
                                    child: Text(
                                      labour.name.isEmpty ? '?' : labour.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Text(
                                      labour.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.grey[900],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Attendance: ${labour.attendance.length}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: orangeAccent, size: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddLabourPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: orangeAccent,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }
}