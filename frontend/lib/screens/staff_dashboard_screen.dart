import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String? _error;
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.getComplaints(activeOnly: _activeOnly);
      if (!mounted) return;
      setState(() {
        _complaints = list;
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

  Future<void> _updateStatus(ComplaintModel complaint, String newStatus) async {
    try {
      await ApiService.updateComplaintStatus(
        complaintId: complaint.id,
        status: newStatus,
        resolutionNotes: newStatus == 'RESOLVED' ? 'Repaired by maintenance team' : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Ticket #${complaint.id} updated to $newStatus! Asset synchronized.'),
        ),
      );
      _loadComplaints();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  void _handleLogout() {
    ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RESOLVED':
      case 'CLOSED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'OPEN':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user?.fullName ?? "Staff"} (${user?.role})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Maintenance & Operations Feed',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Active / All',
            icon: Icon(_activeOnly ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () {
              setState(() => _activeOnly = !_activeOnly);
              _loadComplaints();
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
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
                        FilledButton(onPressed: _loadComplaints, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _complaints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt, size: 56, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            _activeOnly ? 'No open tickets! All clear.' : 'No complaints found.',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadComplaints,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _complaints.length,
                        itemBuilder: (ctx, i) {
                          final c = _complaints[i];
                          final statusColor = _getStatusColor(c.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Title & Status Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.title,
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold),
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

                                  // Location & Asset Chips
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        avatar: const Icon(Icons.meeting_room, size: 14),
                                        label: Text(c.locationName ?? 'Location #${c.locationId}'),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (c.assetName != null)
                                        Chip(
                                          avatar: const Icon(Icons.build, size: 14),
                                          label: Text(c.assetName!),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      Chip(
                                        avatar: const Icon(Icons.flag, size: 14),
                                        label: Text(c.priority),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Action Row for Staff
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (c.status == 'OPEN')
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.hourglass_top, size: 16),
                                          label: const Text('In Progress'),
                                          onPressed: () => _updateStatus(c, 'IN_PROGRESS'),
                                        ),
                                      const SizedBox(width: 8),
                                      if (c.status != 'RESOLVED' && c.status != 'CLOSED')
                                        FilledButton.icon(
                                          icon: const Icon(Icons.check_circle, size: 16),
                                          label: const Text('Resolve'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                          ),
                                          onPressed: () => _updateStatus(c, 'RESOLVED'),
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
    );
  }
}
