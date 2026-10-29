import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AssetModel> _assets = [];
  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String? _error;

  int get _roomId => ApiService.currentUser?.allocatedRoomId ?? 1;
  String get _roomName => ApiService.currentUser?.roomName ?? 'Room 101';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assetsFuture = ApiService.getAssets(_roomId);
      final complaintsFuture = ApiService.getComplaints(locationId: _roomId);

      final results = await Future.wait([assetsFuture, complaintsFuture]);

      if (!mounted) return;
      setState(() {
        _assets = results[0] as List<AssetModel>;
        _complaints = results[1] as List<ComplaintModel>;
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
        content: const Text('Are you sure you want to sign out of the Student Portal?'),
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

  void _showReportDialog({AssetModel? preselectedAsset}) {
    final titleController = TextEditingController(
      text: preselectedAsset != null ? '${preselectedAsset.name} Issue' : '',
    );
    final descController = TextEditingController();
    String priority = 'MEDIUM';
    int? selectedAssetId = preselectedAsset?.id;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Raise Maintenance Complaint',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Asset Dropdown
                  DropdownButtonFormField<int?>(
                    initialValue: selectedAssetId,
                    decoration: const InputDecoration(
                      labelText: 'Select Fixture / Asset',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('General Room / Structural Issue'),
                      ),
                      ..._assets.map((a) => DropdownMenuItem<int?>(
                            value: a.id,
                            child: Text(a.name),
                          )),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedAssetId = val;
                        if (val != null) {
                          final a = _assets.firstWhere((x) => x.id == val);
                          titleController.text = '${a.name} Issue';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Title Field
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Summary',
                      hintText: 'e.g. Fan making loud noise',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Field
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                      hintText: 'Describe what is wrong and where in the room...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low (Can wait a few days)')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (Normal attention)')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High (Urgent daily impact)')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent (Immediate safety/power)')),
                    ],
                    onChanged: (val) {
                      setModalState(() => priority = val ?? 'MEDIUM');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: const Text('Submit Complaint', style: TextStyle(fontSize: 16)),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final desc = descController.text.trim();

                            if (title.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title and description.')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              await ApiService.createComplaint(
                                locationId: _roomId,
                                assetId: selectedAssetId,
                                title: title,
                                description: desc,
                                priority: priority,
                              );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Complaint filed! Ticket logged in hostel queue.'),
                                ),
                              );
                              _loadData();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WORKING':
      case 'RESOLVED':
      case 'CLOSED':
        return Colors.green;
      case 'COMPLAINT_RAISED':
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'DAMAGED':
      case 'OPEN':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getAssetIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fan')) return Icons.mode_fan_off_outlined;
    if (lower.contains('cot') || lower.contains('bed')) return Icons.bed_outlined;
    if (lower.contains('table') || lower.contains('desk')) return Icons.table_restaurant_outlined;
    if (lower.contains('chair')) return Icons.chair_outlined;
    if (lower.contains('light')) return Icons.lightbulb_outline;
    return Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.fullName ?? 'Student Portal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Brahmaputra Hostel · Allocated: $_roomName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2_outlined), text: 'Room Fixtures (${_assets.length})'),
            Tab(icon: const Icon(Icons.confirmation_number_outlined), text: 'My Complaints (${_complaints.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Report Issue'),
        onPressed: () => _showReportDialog(),
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
                        FilledButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Room Assets
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _assets.isEmpty
                          ? const Center(child: Text('No assets recorded for this room.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _assets.length,
                              itemBuilder: (ctx, i) {
                                final asset = _assets[i];
                                final badgeColor = _getStatusColor(asset.status);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
                                  ),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    leading: CircleAvatar(
                                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                                      child: Icon(_getAssetIcon(asset.name), color: badgeColor),
                                    ),
                                    title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            asset.status.replaceAll('_', ' '),
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (asset.comment != null && asset.comment!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('Note: ${asset.comment!}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                    trailing: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        foregroundColor: badgeColor,
                                        side: BorderSide(color: badgeColor),
                                      ),
                                      onPressed: () => _showReportDialog(preselectedAsset: asset),
                                      child: const Text('Report'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Tab 2: Complaints List
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _complaints.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                                  const SizedBox(height: 12),
                                  const Text('No complaints logged for your room!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('All room fixtures are in working condition.', style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _complaints.length,
                              itemBuilder: (ctx, i) {
                                final c = _complaints[i];
                                final statusColor = _getStatusColor(c.status);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                c.status.replaceAll('_', ' '),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(c.description, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                                        const SizedBox(height: 10),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text('Ticket: ${c.displayIvrsNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                            if (c.assetName != null) ...[
                                              const SizedBox(width: 8),
                                              Text('·', style: TextStyle(color: Colors.grey.shade500)),
                                              const SizedBox(width: 8),
                                              Text('Item: ${c.assetName!}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                            ],
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(c.priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                                            ),
                                          ],
                                        ),
                                        if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.task_alt, color: Colors.green, size: 16),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Resolution: ${c.resolutionNotes!}',
                                                    style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
