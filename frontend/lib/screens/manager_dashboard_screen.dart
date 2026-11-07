import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/complaint_model.dart';
import '../models/asset_model.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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

  void _showAdjudicateDisputeDialog(ComplaintModel complaint) {
    String decision = 'WAIVE'; // WAIVE, UPHOLD, REOPEN
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              const Text('Adjudicate Dispute'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Contested by: ${complaint.disputeRaisedBy ?? "Resident"}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${complaint.disputeReason ?? "No reason provided"}"',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  decoration: const InputDecoration(
                    labelText: 'Adjudication Action',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'WAIVE',
                      child: Text('Waive Assessment / Penalty (Resolve)'),
                    ),
                    DropdownMenuItem(
                      value: 'UPHOLD',
                      child: Text('Uphold Assessment (Resolve)'),
                    ),
                    DropdownMenuItem(
                      value: 'REOPEN',
                      child: Text('Re-open for Physical Re-inspection (In Progress)'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => decision = v ?? 'WAIVE'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Executive Adjudication Remarks',
                    hintText: 'Enter formal remarks explaining the decision...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 16),
              label: const Text('Finalize Adjudication'),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final notes = notesController.text.trim();
                      if (notes.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter adjudication remarks.')),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        String newStatus = (decision == 'REOPEN') ? 'IN_PROGRESS' : 'RESOLVED';
                        String fullNotes = '[Manager Adjudication: $decision] $notes';

                        await ApiService.updateComplaintStatus(
                          complaintId: complaint.id,
                          status: newStatus,
                          resolutionNotes: (newStatus == 'RESOLVED') ? fullNotes : complaint.resolutionNotes,
                          disputeResolutionNotes: fullNotes,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadDashboardData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dispute for ${complaint.displayIvrsNumber} successfully adjudicated ($decision).'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    },
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
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Diagnostics'),
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
                    _buildAiAnomaliesTab(theme),
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
    final disputedComplaints = s['disputedComplaints'] ??
        _allComplaints.where((c) => c.status == 'DISPUTED' || c.isDisputed).length;
    final hazardComplaints = s['hazardComplaints'] ??
        _allComplaints.where((c) => c.isHazard).length;

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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Triage & Diagnostics Active',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6 Grid KPI Cards in 2 rows
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Disputes',
                  value: '$disputedComplaints',
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  icon: Icons.gavel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Hazards',
                  value: '$hazardComplaints',
                  color: Colors.pink.shade700,
                  bgColor: Colors.pink.shade50,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: bgColor,
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsTab(ThemeData theme) {
    final filtered = _allComplaints.where((c) {
      if (_complaintStatusFilter == 'ALL') return true;
      if (_complaintStatusFilter == 'DISPUTED') return c.status == 'DISPUTED' || c.isDisputed;
      if (_complaintStatusFilter == 'HAZARDS') return c.isHazard;
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
                _buildFilterChip('DISPUTED', 'Disputed (${_allComplaints.where((c) => c.status == 'DISPUTED' || c.isDisputed).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('HAZARDS', 'Hazards (${_allComplaints.where((c) => c.isHazard).length})'),
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
                    final isHazard = c.isHazard;
                    final isDisputed = c.status == 'DISPUTED' || c.isDisputed;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isHazard
                              ? Colors.red.shade400
                              : (isDisputed ? Colors.amber.shade400 : Colors.grey.shade200),
                          width: isHazard || isDisputed ? 1.5 : 1.0,
                        ),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Critical Hazard Alert Banner
                            if (isHazard) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'CRITICAL SAFETY HAZARD · Priority Escalation',
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Header row: IVRS + Badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.displayIvrsNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildCategoryBadge(c.aiCategory),
                                  ],
                                ),
                                _buildStatusBadge(c.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(c.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),

                            // AI Recommendation
                            if (c.aiRecommendation != null && c.aiRecommendation!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blueGrey.shade100),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'AI Recommendation: ${c.aiRecommendation}',
                                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Contested Dispute Banner
                            if (isDisputed) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.gavel_rounded, size: 16, color: Colors.purple.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Assessment Contested by ${c.disputeRaisedBy ?? "Resident"}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.purple.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${c.disputeReason ?? "No reason given"}"',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                                    ),
                                    if (c.disputeResolutionNotes != null && c.disputeResolutionNotes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Prior Adjudication: ${c.disputeResolutionNotes}',
                                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.purple.shade100,
                                          foregroundColor: Colors.purple.shade900,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.gavel, size: 14),
                                        label: const Text('Adjudicate Dispute', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showAdjudicateDisputeDialog(c),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

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
                                Text(
                                  'Priority: ${c.priority}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _priorityColor(c.priority),
                                  ),
                                ),
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

  Widget _buildCategoryBadge(String? category) {
    final cat = (category ?? 'GENERAL').toUpperCase();
    IconData icon = Icons.build_outlined;
    Color color = Colors.blueGrey;

    if (cat.contains('ELECTRICAL')) {
      icon = Icons.bolt;
      color = Colors.amber.shade800;
    } else if (cat.contains('PLUMBING')) {
      icon = Icons.water_drop;
      color = Colors.blue.shade700;
    } else if (cat.contains('CARPENTRY') || cat.contains('FURNITURE')) {
      icon = Icons.chair_outlined;
      color = Colors.brown.shade700;
    } else if (cat.contains('CIVIL') || cat.contains('STRUCTURAL')) {
      icon = Icons.foundation;
      color = Colors.deepOrange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            cat,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
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
    } else if (status == 'DISPUTED') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
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

  Widget _buildAiAnomaliesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Header Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E3A8A),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 30),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Predictive Maintenance Engine',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Proactive fault anomaly detection across 48 monitored assets and Brahmaputra electrical/civil conduits.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Detected Anomalies & Degraded Assets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),

        // Anomaly 1: Ceiling Fan Bearing Degradation
        _buildAnomalyCard(
          title: 'Recurring Ceiling Fan Motor Bearing Wear',
          location: 'Floor 1 (Rooms 101, 102)',
          riskLevel: 'HIGH',
          anomalyDescription: '3 separate complaints within 30 days citing high humming noise and speed throttling. Pattern matches premature capacitor leakage.',
          recommendation: 'Replace standard 2.5µF capacitors with heavy-duty surge-resistant units during upcoming mid-term break.',
          estimatedSavings: '₹1,800 saved vs emergency contractor replacement',
          icon: Icons.wind_power,
        ),
        const SizedBox(height: 12),

        // Anomaly 2: Water Line Seepage Risk
        _buildAnomalyCard(
          title: 'Restroom Valve Seepage & Water Hammer Anomaly',
          location: '2nd Floor West Wing Common Restroom',
          riskLevel: 'CRITICAL',
          anomalyDescription: 'Repeated flush valve pressure spike detected; potential slow slab leakage into 1st floor electrical conduits.',
          recommendation: 'Isolate supply riser #4 and install pressure-regulating bypass valve within 24 hours.',
          estimatedSavings: 'Prevents estimated ₹35,000 in electrical shaft rewiring',
          icon: Icons.plumbing,
        ),
        const SizedBox(height: 12),

        // Anomaly 3: Routine Inspection Discrepancy
        _buildAnomalyCard(
          title: 'Unlogged Fixture Degradation (Occupancy Audit)',
          location: 'Rooms 204, 205 (Double Sharing)',
          riskLevel: 'MODERATE',
          anomalyDescription: 'Asset condition marked OK during intake, but student reported study table laminate fracture 48h later.',
          recommendation: 'Scheduled for staff re-walkthrough with asset photo verification.',
          estimatedSavings: 'Protects student deposit integrity and prevents dispute friction',
          icon: Icons.checklist_rtl,
        ),
      ],
    );
  }

  Widget _buildAnomalyCard({
    required String title,
    required String location,
    required String riskLevel,
    required String anomalyDescription,
    required String recommendation,
    required String estimatedSavings,
    required IconData icon,
  }) {
    Color riskColor = Colors.orange.shade700;
    Color riskBg = Colors.orange.shade50;
    if (riskLevel == 'CRITICAL') {
      riskColor = Colors.red.shade700;
      riskBg = Colors.red.shade50;
    } else if (riskLevel == 'HIGH') {
      riskColor = Colors.deepOrange.shade700;
      riskBg = Colors.deepOrange.shade50;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: riskBg,
                  child: Icon(icon, color: riskColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(location, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: riskBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    riskLevel,
                    style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(anomalyDescription, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 6),
                      Text('AI Prescriptive Action:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(recommendation, style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.savings_outlined, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(estimatedSavings, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                      final type = loc['type'] ?? 'ROOM';
                      IconData locIcon = Icons.meeting_room_outlined;
                      if (type == 'RESTROOM') locIcon = Icons.bathtub_outlined;
                      if (type == 'COMMON_AREA') locIcon = Icons.local_laundry_service_outlined;

                      return ExpansionTile(
                        leading: Icon(locIcon, color: const Color(0xFF1E3A8A)),
                        title: Text('${loc['name'] ?? 'Unnamed'} ($type)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Complaints: ${loc['activeComplaintsCount'] ?? 0} · Tap to inspect fixtures', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                        children: [
                          FutureBuilder<List<AssetModel>>(
                            future: ApiService.getAssets(loc['id'] as int),
                            builder: (ctx, aSnap) {
                              if (aSnap.connectionState == ConnectionState.waiting) {
                                return const Padding(padding: EdgeInsets.all(8), child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))));
                              }
                              final assets = aSnap.data ?? [];
                              if (assets.isEmpty) {
                                return const Padding(padding: EdgeInsets.all(8), child: Text('No fixtures mapped.', style: TextStyle(fontSize: 12, color: Colors.grey)));
                              }
                              return Column(
                                children: assets.map((a) {
                                  final isWorking = a.isWorking;
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(isWorking ? Icons.check_circle_outline : Icons.error_outline, size: 16, color: isWorking ? Colors.green : Colors.red),
                                    title: Text(a.name, style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(a.comment ?? (isWorking ? 'Operational' : 'Degraded'), style: const TextStyle(fontSize: 11)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isWorking ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(a.status, style: TextStyle(color: isWorking ? Colors.green.shade700 : Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
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
