import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/complaint_model.dart';
import 'login_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _summary;
  List<dynamic> _floors = [];
  List<ComplaintModel> _allComplaints = [];
  String _complaintStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaryFuture = ApiService.getDashboardSummary(hostelId: 1);
      final floorsFuture = ApiService.getFloors(hostelId: 1);
      final complaintsFuture = ApiService.getComplaints(hostelId: 1);

      final results = await Future.wait([summaryFuture, floorsFuture, complaintsFuture]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _floors = results[1] as List<dynamic>;
        _allComplaints = results[2] as List<ComplaintModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the Manager Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    int selectedFloor = _floors.isNotEmpty ? _floors.first['id'] as int : 1;
    String locationType = 'ROOM';
    String roomType = 'DOUBLE';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_home_work, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('Add New Location'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedFloor,
                  decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                  items: _floors.map<DropdownMenuItem<int>>((f) {
                    return DropdownMenuItem<int>(
                      value: f['id'] as int,
                      child: Text('Floor ${f['floorNumber']}'),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedFloor = v ?? selectedFloor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room / Area Name',
                    hintText: 'e.g. Room RR-105 or TT Arena',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: locationType,
                  decoration: const InputDecoration(labelText: 'Location Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ROOM', child: Text('Student Room')),
                    DropdownMenuItem(value: 'RESTROOM', child: Text('Restroom')),
                    DropdownMenuItem(value: 'COMMON_AREA', child: Text('Common Area')),
                  ],
                  onChanged: (v) => setDialogState(() => locationType = v ?? 'ROOM'),
                ),
                if (locationType == 'ROOM') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: roomType,
                    decoration: const InputDecoration(labelText: 'Room Sharing Capacity', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'SINGLE', child: Text('Single Sharing (1 Person)')),
                      DropdownMenuItem(value: 'DOUBLE', child: Text('Double Sharing (2 Persons)')),
                      DropdownMenuItem(value: 'TRIPLE', child: Text('Triple Sharing (3 Persons)')),
                    ],
                    onChanged: (v) => setDialogState(() => roomType = v ?? 'DOUBLE'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        await ApiService.createLocation(
                          floorId: selectedFloor,
                          name: name,
                          type: locationType,
                          roomType: locationType == 'ROOM' ? roomType : null,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadDashboardData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully added $name!')),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Location'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ApiService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brahmaputra Hostel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Executive Management Portal · ${user?.fullName ?? "Manager"}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview & KPIs'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Complaint Feed'),
            Tab(icon: Icon(Icons.layers_outlined), text: 'Floors & Rooms'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Location'),
        onPressed: _showAddLocationDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _loadDashboardData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(theme),
                    _buildComplaintsTab(theme),
                    _buildFloorsTab(theme),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final s = _summary ?? {};
    final totalAssets = s['totalAssets'] ?? 0;
    final assetsWithIssues = s['assetsWithIssues'] ?? 0;
    final totalComplaints = s['totalComplaints'] ?? 0;
    final openComplaints = s['openComplaints'] ?? 0;
    final inProgress = s['inProgressComplaints'] ?? 0;
    final resolved = s['resolvedComplaints'] ?? 0;
    final inspectionRate = (s['inspectionRate'] as num?)?.toDouble() ?? 100.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hero Metrics Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: (inspectionRate / 100).clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            inspectionRate >= 90
                                ? Colors.green.shade600
                                : (inspectionRate >= 70 ? Colors.amber.shade600 : Colors.red.shade600),
                          ),
                        ),
                      ),
                      Text(
                        '${inspectionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hostel Operational Health',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalAssets total assets monitored · $assetsWithIssues reported with active issues',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Grid KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Open Issues',
                  value: '$openComplaints',
                  color: Colors.red.shade600,
                  bgColor: Colors.red.shade50,
                  icon: Icons.error_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'In Progress',
                  value: '$inProgress',
                  color: Colors.orange.shade700,
                  bgColor: Colors.orange.shade50,
                  icon: Icons.hourglass_top,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Resolved',
                  value: '$resolved',
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Tickets',
                  value: '$totalComplaints',
                  color: const Color(0xFF1E3A8A),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.receipt_long,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Banner
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hostel Admin Controls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Manage rooms, floors, and inspect infrastructure', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _showAddLocationDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Text('Add Room'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: bgColor,
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsTab(ThemeData theme) {
    final filtered = _allComplaints.where((c) {
      if (_complaintStatusFilter == 'ALL') return true;
      return c.status.toUpperCase() == _complaintStatusFilter;
    }).toList();

    return Column(
      children: [
        // Status filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${_allComplaints.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('OPEN', 'Open (${_allComplaints.where((c) => c.status == 'OPEN').length})'),
                const SizedBox(width: 8),
                _buildFilterChip('IN_PROGRESS', 'In Progress (${_allComplaints.where((c) => c.status == 'IN_PROGRESS').length})'),
                const SizedBox(width: 8),
                _buildFilterChip('RESOLVED', 'Resolved (${_allComplaints.where((c) => c.status == 'RESOLVED').length})'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No complaints matching $_complaintStatusFilter', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.displayIvrsNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                                _buildStatusBadge(c.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(c.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(c.displayLocationName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                if (c.assetName != null) ...[
                                  const SizedBox(width: 8),
                                  Text('·', style: TextStyle(color: Colors.grey.shade500)),
                                  const SizedBox(width: 8),
                                  Text(c.assetName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                                const Spacer(),
                                Text('Priority: ${c.priority}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _priorityColor(c.priority))),
                              ],
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
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _complaintStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _complaintStatusFilter = key),
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    if (status == 'OPEN') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (status == 'IN_PROGRESS') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (status == 'RESOLVED') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
      case 'HIGH':
        return Colors.red.shade700;
      case 'MEDIUM':
        return Colors.orange.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget _buildFloorsTab(ThemeData theme) {
    if (_floors.isEmpty) {
      return const Center(child: Text('No floors configured'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _floors.length,
      itemBuilder: (ctx, i) {
        final floor = _floors[i];
        final floorNumber = floor['floorNumber'] ?? (i + 1);
        final floorId = floor['id'] as int;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              child: Text('$floorNumber'),
            ),
            title: Text('Floor $floorNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Brahmaputra Hostel'),
            children: [
              FutureBuilder<List<dynamic>>(
                future: ApiService.getLocations(floorId),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                  }
                  final locations = snapshot.data ?? [];
                  if (locations.isEmpty) {
                    return const Padding(padding: EdgeInsets.all(16), child: Text('No rooms on this floor'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, li) {
                      final loc = locations[li];
                      final isOk = loc['status'] == 'OK';
                      return ListTile(
                        leading: Icon(
                          loc['type'] == 'ROOM' ? Icons.meeting_room_outlined : Icons.wb_shade_outlined,
                          color: const Color(0xFF1E3A8A),
                        ),
                        title: Text(loc['name'] ?? 'Unnamed'),
                        subtitle: Text('Type: ${loc['type']} · Complaints: ${loc['activeComplaintsCount'] ?? 0}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOk ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOk ? 'OK' : 'ISSUES',
                            style: TextStyle(color: isOk ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
