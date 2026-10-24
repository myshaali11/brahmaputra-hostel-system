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

  void _handleLogout() {
    ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
                      Text(
                        'Report Room Issue',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                    value: selectedAssetId,
                    decoration: const InputDecoration(
                      labelText: 'Select Fixture (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('General Room Issue'),
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
                      labelText: 'Title / Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Field
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Describe the problem...',
                      hintText: 'e.g. Fan making loud squeaking noise, study table drawer broken',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => priority = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  FilledButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSubmitting ? 'Submitting...' : 'Submit Complaint'),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final desc = descController.text.trim();
                            final title = titleController.text.trim();

                            if (desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please describe the problem')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              await ApiService.createComplaint(
                                locationId: _roomId,
                                assetId: selectedAssetId,
                                title: title.isEmpty ? 'Room Issue' : title,
                                description: desc,
                                priority: priority,
                              );

                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Complaint filed! Asset status updated.'),
                                ),
                              );
                              _loadData(); // Reload live data
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
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
    switch (status) {
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.fullName ?? 'Student Portal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Hostel: Brahmaputra • $_roomName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2_outlined), text: 'Fixtures (${_assets.length})'),
            Tab(icon: const Icon(Icons.confirmation_number_outlined), text: 'Complaints (${_complaints.length})'),
          ],
        ),
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
                        Text(_error!, textAlign: TextAlign.center),
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
                              padding: const EdgeInsets.all(12),
                              itemCount: _assets.length,
                              itemBuilder: (ctx, i) {
                                final asset = _assets[i];
                                final badgeColor = _getStatusColor(asset.status);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: badgeColor.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: badgeColor.withOpacity(0.15),
                                      child: Icon(_getAssetIcon(asset.name), color: badgeColor),
                                    ),
                                    title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.1),
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
                                          Text(
                                            'Note: ${asset.comment}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: asset.hasComplaint
                                        ? const Tooltip(
                                            message: 'Complaint Active',
                                            child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                          )
                                        : TextButton.icon(
                                            icon: const Icon(Icons.report_problem_outlined, size: 16),
                                            label: const Text('Report'),
                                            onPressed: () => _showReportDialog(preselectedAsset: asset),
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
                          ? const Center(child: Text('No complaints filed for your room yet.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _complaints.length,
                              itemBuilder: (ctx, i) {
                                final c = _complaints[i];
                                final statusColor = _getStatusColor(c.status);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                                c.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                c.status,
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
                                        Text(c.description, style: TextStyle(color: Colors.grey.shade800)),
                                        const SizedBox(height: 10),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              c.ivrsNumber != null ? 'Ticket: ${c.ivrsNumber}' : 'Room: $_roomName',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                            Text(
                                              'Priority: ${c.priority}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: c.priority == 'HIGH' || c.priority == 'URGENT'
                                                    ? Colors.red
                                                    : Colors.blueGrey,
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
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Report Issue'),
        onPressed: () => _showReportDialog(),
      ),
    );
  }
}
