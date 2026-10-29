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
  String _filterStatus = 'ALL';

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
      final list = await ApiService.getComplaints(
        activeOnly: _filterStatus == 'ACTIVE' ? true : null,
      );
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

  Future<void> _showUpdateDialog(ComplaintModel complaint) async {
    String selectedStatus = complaint.status;
    final notesController = TextEditingController(text: complaint.resolutionNotes ?? '');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Update Ticket #${complaint.ivrsNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(complaint.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v ?? selectedStatus),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Staff Resolution Notes',
                    hintText: 'e.g. Fan capacitor replaced and tested',
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
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ApiService.updateComplaintStatus(
                          complaintId: complaint.id,
                          status: selectedStatus,
                          resolutionNotes: notesController.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadComplaints();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Ticket ${complaint.displayIvrsNumber} updated to $selectedStatus!'),
                          ),
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
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInspectRoomDialog() {
    final locationIdController = TextEditingController(text: '1');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.checklist_rtl, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('Record Room Inspection'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Stamp an official inspection check-in/vacancy round for a room.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: locationIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Location / Room ID',
                  hintText: 'e.g. 1 for Room 101',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final id = int.tryParse(locationIdController.text.trim()) ?? 1;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final staffName = ApiService.currentUser?.fullName ?? 'Maintenance Staff 1';
                        await ApiService.markInspected(locationId: id, staffName: staffName);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.green, content: Text('Location #$id stamped inspected by $staffName!')),
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
                  : const Text('Stamp Inspected'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the Staff Portal?'),
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
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

    final filtered = _complaints.where((c) {
      if (_filterStatus == 'ALL') return true;
      return c.status.toUpperCase() == _filterStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user?.fullName ?? "Staff"} (${user?.role})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Brahmaputra Hostel Maintenance Portal',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Feed',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Inspect Room'),
        onPressed: _showInspectRoomDialog,
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${_complaints.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('OPEN', 'Open (${_complaints.where((c) => c.status == 'OPEN').length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'In Progress (${_complaints.where((c) => c.status == 'IN_PROGRESS').length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RESOLVED', 'Resolved (${_complaints.where((c) => c.status == 'RESOLVED').length})'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
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
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.task_alt, size: 56, color: Colors.green),
                                const SizedBox(height: 12),
                                Text(
                                  'No tickets matching $_filterStatus!',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadComplaints,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final c = filtered[i];
                                final statusColor = _getStatusColor(c.status);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Colors.white,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showUpdateDialog(c),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(c.displayIvrsNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  c.status.replaceAll('_', ' '),
                                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(c.description, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                                          const SizedBox(height: 12),
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
                                              TextButton.icon(
                                                onPressed: () => _showUpdateDialog(c),
                                                icon: const Icon(Icons.edit_note, size: 16),
                                                label: const Text('Update'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = key),
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
