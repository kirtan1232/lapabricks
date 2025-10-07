import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lapabricks/pages/add_labour_page.dart';
import 'package:lapabricks/pages/labour_detail_page.dart';
import 'package:lapabricks/pages/daily_total_page.dart';
import 'package:lapabricks/pdf/pdf_view_page.dart';
import 'package:lapabricks/auth/register_page.dart';
import 'package:lapabricks/connection/connection_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  final String userRole;
  const HomePage({Key? key, this.userRole = 'user'}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  // Loading flags for actions to block double tap
  bool _isPdfLoading = false;
  bool _isStatementLoading = false;

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

  Future<void> _onPdfTap(BuildContext context) async {
    if (_isPdfLoading) return;
    setState(() => _isPdfLoading = true);
    try {
      await _exportTodayPdf(context);
    } catch (e) {
      // Optionally handle error
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  Future<void> _onStatementTap(BuildContext context) async {
    if (_isStatementLoading) return;
    setState(() => _isStatementLoading = true);

    try {
      // Removed timeout and ConnectionPage. 
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyTotalPage()),
      );
    } catch (e) {
      // Optionally handle error
    } finally {
      if (mounted) setState(() => _isStatementLoading = false);
    }
  }

  Future<void> _exportTodayPdf(BuildContext context) async {
    final store = Provider.of<LabourStore>(context, listen: false);
    final labours = store.labours;
    final today = DateTime.now();
    final dateStr =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    DailyTotal? todayTotal;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('daily_total')
          .doc(dateStr)
          .get();
      if (doc.exists) {
        todayTotal =
            DailyTotal.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      todayTotal = null;
    }
    todayTotal ??= DailyTotal(
      date: dateStr,
      labourTotalLifts: 0,
      labourTotalEarnings: 0,
      driverTotalLifts: 0,
      driverTotalEarnings: 0,
      staffTotalEarnings: 0,
      overallTotalLifts: 0,
      overallTotalEarnings: 0,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewPage(
          date: dateStr,
          labours: labours,
          dailyTotal: todayTotal!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LabourStore>();
    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightBlue = Color(0xFF3B82F6);
    const Color accentTeal = Color(0xFF06B6D4);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF1E293B);
    const Color lightGray = Color(0xFF64748B);

    final isWebAdmin = kIsWeb && widget.userRole == 'admin';
    final isScanOnly = widget.userRole == 'scanonly';

    if (!store.loaded) {
      return Scaffold(
        backgroundColor: backgroundGray,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            strokeWidth: 3,
          ),
        ),
      );
    }

    final labours = store.labours
        .where((labour) =>
            _searchQuery.isEmpty ||
            labour.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        titleSpacing: 0,
        centerTitle: true,
        leading: (!_showSearchBar && !isScanOnly)
            ? IconButton(
                icon: Icon(Icons.stacked_line_chart, color: accentTeal, size: 28),
                tooltip: 'Daily Statement',
                onPressed: _isStatementLoading ? null : () => _onStatementTap(context),
              )
            : null,
        title: _showSearchBar
            ? Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                  style: const TextStyle(fontSize: 16, color: darkGray),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    hintText: "Search labour...",
                    hintStyle: TextStyle(color: lightGray, fontSize: 15),
                    filled: true,
                    fillColor: backgroundGray,
                    prefixIcon:
                        Icon(Icons.search_rounded, color: primaryBlue, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close_rounded, color: lightGray, size: 20),
                      onPressed: _toggleSearchBar,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryBlue, width: 2),
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LAPA BRICKS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 3,
                      width: 60,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, accentTeal],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (!_showSearchBar) ...[
            if (isScanOnly)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Search',
                  icon: Icon(Icons.search_rounded, color: primaryBlue, size: 26),
                  onPressed: _toggleSearchBar,
                  style: IconButton.styleFrom(
                    backgroundColor: backgroundGray,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            if (!isScanOnly) ...[
              if (kIsWeb)
                IconButton(
                  icon: Icon(Icons.refresh, color: accentTeal, size: 28),
                  tooltip: 'Reload data',
                  onPressed: () async {
                    await store.loadLaboursAsync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data reloaded')),
                    );
                  },
                ),
              IconButton(
                icon: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                tooltip: 'Export Today PDF',
                onPressed: _isPdfLoading ? null : () => _onPdfTap(context),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Search',
                  icon: Icon(Icons.search_rounded, color: primaryBlue, size: 26),
                  onPressed: _toggleSearchBar,
                  style: IconButton.styleFrom(
                    backgroundColor: backgroundGray,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth < 550
                ? constraints.maxWidth * 0.98
                : constraints.maxWidth < 1000
                    ? 540
                    : 720;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    if (isWebAdmin) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Admin Controls",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add),
                                  label: const Text("Add Labour"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AddLabourPage(),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.account_circle),
                                  label: const Text("Create Account"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: labours.isEmpty
                          ? ListView(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: cardWhite,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset('assets/logo.png', height: 100),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'No labours yet!'
                                          : 'No labours match your search.',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: darkGray,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'Tap the Add button to start.'
                                          : 'Try changing your search.',
                                      style: TextStyle(
                                        color: lightGray,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: labours.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final labour = labours[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: isScanOnly
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => LabourDetailPage(
                                                labourId: labour.id,
                                                userRole: widget.userRole,
                                              ),
                                            ),
                                          ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.04),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [primaryBlue, lightBlue],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryBlue.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              labour.name.isEmpty
                                                  ? '?'
                                                  : labour.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                labour.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 17,
                                                  color: darkGray,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isScanOnly) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .calendar_today_rounded,
                                                      size: 14,
                                                      color: lightGray,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Attendance: ${labour.attendance.length}',
                                                      style: TextStyle(
                                                        color: lightGray,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (!isScanOnly)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: backgroundGray,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: primaryBlue,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}