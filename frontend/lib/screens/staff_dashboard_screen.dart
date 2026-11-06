import 'package:flutter/material.dart';
import '../models/asset_model.dart';
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
    final disputeNotesController = TextEditingController(text: complaint.disputeResolutionNotes ?? '');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Update Ticket #${complaint.displayIvrsNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(complaint.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),

                if (complaint.isDisputed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, color: Colors.deepOrange, size: 16),
                            SizedBox(width: 6),
                            Text('Contested by Resident', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange)),
                          ],
                        ),
                        if (complaint.disputeReason != null) ...[
                          const SizedBox(height: 4),
                          Text('Reason: "${complaint.disputeReason}"', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED')),
                    DropdownMenuItem(value: 'DISPUTED', child: Text('DISPUTED (Contested)')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v ?? selectedStatus),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Staff Resolution Notes',
                    hintText: 'e.g. Fan capacitor replaced and tested speed',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (complaint.isDisputed) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: disputeNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Dispute Adjudication / Response Note',
                      hintText: 'e.g. Verified with resident; pre-existing mark cleared from record.',
                      border: OutlineInputBorder(),
                    ),
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
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ApiService.updateComplaintStatus(
                          complaintId: complaint.id,
                          status: selectedStatus,
                          resolutionNotes: notesController.text.trim(),
                          disputeResolutionNotes: disputeNotesController.text.trim(),
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

  // Interactive Room Walkthrough & Asset Condition Inspection
  Future<void> _showWalkthroughInspectionDialog() async {
    bool isLoadingLocations = true;
    List<dynamic> floors = [];
    List<dynamic> rooms = [];
    int? selectedFloorId;
    int? selectedRoomId;
    String? selectedRoomName;

    List<AssetModel> roomAssets = [];
    Map<int, String> assetStatusMap = {};
    Map<int, TextEditingController> assetCommentControllers = {};
    bool isLoadingAssets = false;
    bool isSubmitting = false;

    try {
      floors = await ApiService.getFloors();
      if (floors.isNotEmpty) {
        selectedFloorId = floors[0]['id'] as int;
        rooms = await ApiService.getLocations(selectedFloorId);
        if (rooms.isNotEmpty) {
          selectedRoomId = rooms[0]['id'] as int;
          selectedRoomName = rooms[0]['name'] as String;
        }
      }
      isLoadingLocations = false;
    } catch (_) {
      isLoadingLocations = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Function to load assets when room changes
          void loadRoomAssets(int roomId, String roomName) async {
            setDialogState(() {
              selectedRoomId = roomId;
              selectedRoomName = roomName;
              isLoadingAssets = true;
            });
            try {
              final assets = await ApiService.getAssets(roomId);
              assetStatusMap.clear();
              assetCommentControllers.clear();
              for (var a in assets) {
                assetStatusMap[a.id] = a.status;
                assetCommentControllers[a.id] = TextEditingController(text: a.comment ?? '');
              }
              setDialogState(() {
                roomAssets = assets;
                isLoadingAssets = false;
              });
            } catch (_) {
              setDialogState(() => isLoadingAssets = false);
            }
          }

          // Initial asset load
          if (selectedRoomId != null && roomAssets.isEmpty && !isLoadingAssets && assetStatusMap.isEmpty) {
            loadRoomAssets(selectedRoomId!, selectedRoomName ?? 'Room');
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.checklist_rtl_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('Room Walkthrough & Audit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: isLoadingLocations
                  ? const Center(heightFactor: 3, child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Step into room, inspect fixtures, toggle condition (Working/Damaged), and record inspection stamp.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),

                          // Floor & Room Selectors
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedFloorId,
                                  decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  items: floors.map<DropdownMenuItem<int>>((f) {
                                    return DropdownMenuItem<int>(
                                      value: f['id'] as int,
                                      child: Text('Floor ${f['floorNumber']}'),
                                    );
                                  }).toList(),
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    selectedFloorId = v;
                                    setDialogState(() => isLoadingAssets = true);
                                    final newRooms = await ApiService.getLocations(v);
                                    rooms = newRooms;
                                    if (newRooms.isNotEmpty) {
                                      loadRoomAssets(newRooms[0]['id'] as int, newRooms[0]['name'] as String);
                                    } else {
                                      setDialogState(() {
                                        selectedRoomId = null;
                                        roomAssets = [];
                                        isLoadingAssets = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedRoomId,
                                  decoration: const InputDecoration(labelText: 'Room / Facility', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  items: rooms.map<DropdownMenuItem<int>>((r) {
                                    final type = r['type'] ?? 'ROOM';
                                    String prefix = '';
                                    if (type == 'RESTROOM') prefix = 'Washroom ';
                                    if (type == 'COMMON_AREA') prefix = 'Facility ';
                                    return DropdownMenuItem<int>(
                                      value: r['id'] as int,
                                      child: Text('$prefix${r['name']}'),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    final roomObj = rooms.firstWhere((element) => element['id'] == v, orElse: () => {'name': 'Room'});
                                    loadRoomAssets(v, roomObj['name'] as String);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Assets Checklist
                          Text(
                            'Fixtures Checklist for ${selectedRoomName ?? "Selected Room"}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 8),

                          if (isLoadingAssets)
                            const Center(heightFactor: 2, child: CircularProgressIndicator())
                          else if (roomAssets.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Text('No fixtures registered for this room yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            )
                          else
                            ...roomAssets.map((asset) {
                              final currentStatus = assetStatusMap[asset.id] ?? asset.status;
                              final isDamaged = currentStatus == 'DAMAGED' || currentStatus == 'COMPLAINT_RAISED';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: isDamaged ? Colors.red.shade300 : Colors.grey.shade300),
                                ),
                                color: isDamaged ? Colors.red.shade50 : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              ChoiceChip(
                                                label: const Text('OK / Working', style: TextStyle(fontSize: 11)),
                                                selected: !isDamaged,
                                                selectedColor: Colors.green.shade100,
                                                onSelected: (val) {
                                                  if (val) {
                                                    setDialogState(() => assetStatusMap[asset.id] = 'WORKING');
                                                  }
                                                },
                                              ),
                                              ChoiceChip(
                                                label: const Text('Damaged', style: TextStyle(fontSize: 11)),
                                                selected: isDamaged,
                                                selectedColor: Colors.red.shade100,
                                                onSelected: (val) {
                                                  if (val) {
                                                    setDialogState(() => assetStatusMap[asset.id] = 'DAMAGED');
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (isDamaged) ...[
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: assetCommentControllers[asset.id],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Describe damage (e.g. blade bent, loose wire)...',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Complete Walkthrough & Stamp'),
                onPressed: isSubmitting || selectedRoomId == null
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final staffName = ApiService.currentUser?.fullName ?? 'Maintenance Staff 1';
                          final assetUpdates = roomAssets.map((a) {
                            return {
                              'assetId': a.id,
                              'status': assetStatusMap[a.id] ?? 'WORKING',
                              'comment': assetCommentControllers[a.id]?.text.trim(),
                            };
                          }).toList();

                          await ApiService.completeWalkthroughInspection(
                            locationId: selectedRoomId!,
                            staffName: staffName,
                            assetUpdates: assetUpdates,
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _loadComplaints();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('Room $selectedRoomName walkthrough completed & stamped by $staffName!'),
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
          );
        },
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
      case 'DISPUTED':
        return Colors.deepOrange;
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
      if (_filterStatus == 'DISPUTED') return c.isDisputed || c.status == 'DISPUTED';
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
        icon: const Icon(Icons.checklist_rtl_rounded),
        label: const Text('Room Walkthrough & Audit'),
        onPressed: _showWalkthroughInspectionDialog,
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
                  _buildFilterChip('DISPUTED', 'Contested (${_complaints.where((c) => c.isDisputed || c.status == 'DISPUTED').length})'),
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

                                          // Dispute Banner
                                          if (c.isDisputed) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade400),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.gavel_rounded, color: Colors.deepOrange, size: 16),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Resident Contested: "${c.disputeReason ?? 'Damage contested'}"',
                                                      style: TextStyle(color: Colors.deepOrange.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

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
