import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
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
  List<dynamic> _floorLocations = [];
  bool _isLoading = true;
  String? _error;

  int get _roomId => ApiService.currentUser?.allocatedRoomId ?? 1;
  String get _roomName => ApiService.currentUser?.roomName ?? 'F01';
  int get _floorNumber => ApiService.currentUser?.floorNumber ?? 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final complaintsFuture = ApiService.getComplaints();
      final floorLocsFuture = ApiService.getMyFloorLocations();

      final results = await Future.wait([assetsFuture, complaintsFuture, floorLocsFuture]);

      if (!mounted) return;
      setState(() {
        _assets = results[0] as List<AssetModel>;
        final allComplaints = results[1] as List<ComplaintModel>;
        final currentUsername = ApiService.currentUser?.username.toLowerCase();
        final currentFullName = ApiService.currentUser?.fullName.toLowerCase();

        // Show complaints filed by this student or associated with their room
        _complaints = allComplaints.where((c) {
          final rep = c.reportedBy?.toLowerCase() ?? '';
          return rep == currentUsername ||
              rep == currentFullName ||
              c.locationId == _roomId;
        }).toList();

        _floorLocations = results[2];
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

  void _showReportDialog({int? targetLocationId, String? targetLocationName, AssetModel? preselectedAsset}) {
    int activeLocationId = targetLocationId ?? _roomId;
    String activeLocationName = targetLocationName ?? _roomName;
    List<AssetModel> locationAssets = activeLocationId == _roomId
        ? List<AssetModel>.from(_assets)
        : (preselectedAsset != null ? [preselectedAsset] : <AssetModel>[]);
    bool isLoadingAssets = activeLocationId != _roomId && locationAssets.isEmpty;

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
          // If assets for a non-room location need loading or more assets are available
          if (activeLocationId != _roomId && (isLoadingAssets || locationAssets.length <= 1)) {
            ApiService.getAssets(activeLocationId).then((loaded) {
              if (ctx.mounted && loaded.isNotEmpty) {
                setModalState(() {
                  final map = {for (var a in loaded) a.id: a};
                  if (preselectedAsset != null) {
                    map[preselectedAsset.id] = preselectedAsset;
                  }
                  locationAssets = map.values.toList();
                  isLoadingAssets = false;
                });
              }
            }).catchError((_) {
              if (ctx.mounted) {
                setModalState(() => isLoadingAssets = false);
              }
            });
          }

          // Build safe location items
          final locationItems = <DropdownMenuItem<int>>[
            DropdownMenuItem<int>(
              value: _roomId,
              child: Text('My Room ($_roomName)'),
            ),
            ..._floorLocations.where((l) => l['id'] != _roomId).map((l) {
              final type = l['type'] ?? 'ROOM';
              String prefix = 'Room';
              if (type == 'RESTROOM') prefix = 'Washroom';
              if (type == 'COMMON_AREA') prefix = 'Facility';
              return DropdownMenuItem<int>(
                value: l['id'] as int,
                child: Text('$prefix ${l['name']}'),
              );
            }),
          ];

          if (!locationItems.any((item) => item.value == activeLocationId)) {
            locationItems.add(
              DropdownMenuItem<int>(
                value: activeLocationId,
                child: Text(activeLocationName),
              ),
            );
          }

          // Build safe asset items
          final assetItems = <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('General Structural / Space Issue'),
            ),
            ...locationAssets.map((a) => DropdownMenuItem<int?>(
                  value: a.id,
                  child: Text('${a.name} (${a.status})'),
                )),
          ];

          if (selectedAssetId != null && !assetItems.any((item) => item.value == selectedAssetId)) {
            assetItems.add(
              DropdownMenuItem<int?>(
                value: selectedAssetId,
                child: Text(preselectedAsset?.name ?? 'Selected Fixture #$selectedAssetId'),
              ),
            );
          }

          final safeSelectedAssetId = assetItems.any((item) => item.value == selectedAssetId)
              ? selectedAssetId
              : null;

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
                      Expanded(
                        child: Text(
                          'Report Maintenance Issue ($activeLocationName)',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
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

                  // Location Selector
                  DropdownButtonFormField<int>(
                    initialValue: activeLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Location / Facility',
                      border: OutlineInputBorder(),
                    ),
                    items: locationItems,
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() {
                        activeLocationId = val;
                        final locMatch = _floorLocations.firstWhere(
                          (element) => element['id'] == val,
                          orElse: () => {'name': _roomName},
                        );
                        activeLocationName = locMatch['name'] ?? 'Facility';
                        selectedAssetId = null;
                        isLoadingAssets = true;
                      });
                      ApiService.getAssets(val).then((loaded) {
                        if (ctx.mounted) {
                          setModalState(() {
                            locationAssets = loaded;
                            isLoadingAssets = false;
                          });
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Asset Dropdown
                  isLoadingAssets
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<int?>(
                          initialValue: safeSelectedAssetId,
                          decoration: const InputDecoration(
                            labelText: 'Select Fixture / Appliance',
                            border: OutlineInputBorder(),
                          ),
                          items: assetItems,
                          onChanged: (val) {
                            setModalState(() {
                              selectedAssetId = val;
                              if (val != null) {
                                final a = locationAssets.firstWhere((x) => x.id == val, orElse: () => preselectedAsset!);
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
                      hintText: 'e.g. Washing machine not spinning / Tap leaking',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Field
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Comments & Notes',
                      hintText: 'Describe the issue, leak, noise, or electrical spark...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority Dropdown (LOW, MEDIUM, HIGH, URGENT supported by backend)
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low (Minor / Can wait a few days)')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (Standard maintenance)')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High (Significant daily impact)')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent (Immediate safety / power / leak)')),
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
                                locationId: activeLocationId,
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
                                SnackBar(
                                  backgroundColor: Colors.green.shade700,
                                  content: Text('Complaint filed for $activeLocationName! Logged in maintenance queue.'),
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
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
        },
      ),
    );
  }

  Future<void> _showDisputeDialog(ComplaintModel complaint) async {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Contest Assessment (${complaint.displayIvrsNumber})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Formal Dispute Workflow: If you believe this damage assessment was incorrect, pre-existing prior to your move-in, or unresolved, submit a formal contest for Manager review.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ticket: ${complaint.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (complaint.resolutionNotes != null && complaint.resolutionNotes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Resolution Note: ${complaint.resolutionNotes}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Dispute Justification',
                    hintText: 'e.g. Damage existed prior to move-in; please verify check-in audit log.',
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
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              icon: isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: const Text('Submit Dispute'),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a dispute justification.')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ApiService.fileDispute(complaintId: complaint.id, reason: reason);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.deepOrange,
                            content: Text('Dispute for ticket ${complaint.displayIvrsNumber} submitted to Manager!'),
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WORKING':
      case 'RESOLVED':
      case 'CLOSED':
      case 'OK':
        return Colors.green;
      case 'DISPUTED':
        return Colors.purple.shade700;
      case 'COMPLAINT_RAISED':
      case 'IN_PROGRESS':
        return Colors.orange.shade800;
      case 'DAMAGED':
      case 'OPEN':
      case 'ISSUES':
        return Colors.red.shade700;
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
    if (lower.contains('washing machine') || lower.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (lower.contains('tap') || lower.contains('water') || lower.contains('shower')) return Icons.water_drop_outlined;
    if (lower.contains('flush') || lower.contains('faucet')) return Icons.plumbing_outlined;
    if (lower.contains('mirror')) return Icons.crop_portrait_outlined;
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
            Text('Brahmaputra Hostel · Room: $_roomName (Floor $_floorNumber)', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.meeting_room_outlined), text: 'My Room ($_roomName)'),
            const Tab(icon: Icon(Icons.wash_outlined), text: 'Floor Washrooms & Laundry'),
            Tab(icon: const Icon(Icons.assignment_outlined), text: 'Complaints (${_complaints.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('File Complaint'),
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
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _loadData, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomTab(user),
                    _buildFloorAmenitiesTab(),
                    _buildComplaintsTab(),
                  ],
                ),
    );
  }

  Widget _buildRoomTab(UserModel? user) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: const Color(0xFFEFF6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 36, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room $_roomName — Resident Inventory', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 4),
                        Text('Student: ${user?.fullName ?? user?.username} (${user?.email ?? ""})', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Assigned Room Fixtures & Operational Status:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          if (_assets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No fixtures mapped to this room yet.'),
              ),
            )
          else
            ..._assets.map((asset) {
              final statusColor = _getStatusColor(asset.status);
              final icon = _getAssetIcon(asset.name);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(icon, color: statusColor),
                  ),
                  title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    asset.comment != null && asset.comment!.isNotEmpty
                        ? 'Note: ${asset.comment!}'
                        : 'Routine operational fixture',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          asset.status.replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.report_problem_outlined, size: 20, color: Colors.red),
                        tooltip: 'Report issue with ${asset.name}',
                        onPressed: () => _showReportDialog(
                          targetLocationId: _roomId,
                          targetLocationName: _roomName,
                          preselectedAsset: asset,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFloorAmenitiesTab() {
    final laundryLocs = _floorLocations.where((l) =>
        (l['type'] == 'COMMON_AREA') || (l['name']?.toString().contains('Laundry') ?? false)).toList();
    final washroomLocs = _floorLocations.where((l) =>
        (l['type'] == 'RESTROOM') || (l['name']?.toString().startsWith('RR') ?? false)).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Card(
            elevation: 0,
            color: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blueGrey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.apartment_outlined, size: 36, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Floor $_floorNumber Amenities & Washrooms',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Access washrooms (RR1-RR10) and laundry appliances on your floor. Tap any fixture to view health or report faults.',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: Laundry & Washing Machines
          Row(
            children: [
              Icon(Icons.local_laundry_service, size: 20, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              const Text('Floor Laundry & Washing Machines', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          if (laundryLocs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Common laundry facility currently being mapped.'),
              ),
            )
          else
            ...laundryLocs.map((loc) {
              final locId = loc['id'] as int;
              final locName = loc['name'] as String;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFEFF6FF),
                                child: Icon(Icons.local_laundry_service, size: 16, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(width: 8),
                              Text(locName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.add_comment_outlined, size: 14),
                            label: const Text('Report Appliance', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showReportDialog(
                              targetLocationId: locId,
                              targetLocationName: locName,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<AssetModel>>(
                        future: ApiService.getAssets(locId),
                        builder: (ctx, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          }
                          final appliances = snapshot.data ?? [];
                          if (appliances.isEmpty) {
                            return const Text('No appliances listed yet.');
                          }
                          return Column(
                            children: appliances.map((app) {
                              final statusColor = _getStatusColor(app.status);
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(_getAssetIcon(app.name), size: 22, color: const Color(0xFF1E3A8A)),
                                title: Text(app.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  app.comment != null && app.comment!.isNotEmpty
                                      ? app.comment!
                                      : 'Routine operational appliance',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        app.status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.report_problem_outlined, size: 18, color: Colors.red),
                                      tooltip: 'Report fault with ${app.name}',
                                      onPressed: () => _showReportDialog(
                                        targetLocationId: locId,
                                        targetLocationName: locName,
                                        preselectedAsset: app,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Section 2: Floor Washrooms
          Row(
            children: [
              Icon(Icons.wash, size: 20, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Text(
                'Floor Washrooms & Restrooms (${washroomLocs.length} mapped)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (washroomLocs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Washrooms currently loading or being synchronized.'),
              ),
            )
          else
            ...washroomLocs.map((loc) {
              final locId = loc['id'] as int;
              final locName = loc['name'] as String;
              final isOk = (loc['status'] ?? 'OK') == 'OK';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isOk ? Colors.blue.shade50 : Colors.red.shade50,
                    child: Icon(
                      Icons.bathtub_outlined,
                      color: isOk ? const Color(0xFF1E3A8A) : Colors.red.shade700,
                    ),
                  ),
                  title: Text(
                    'Washroom $locName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Complaints: ${loc['activeComplaintsCount'] ?? 0} · Tap to view fixtures',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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
                      future: ApiService.getAssets(locId),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        }
                        final fixtures = snapshot.data ?? [];
                        if (fixtures.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No fixtures mapped for this washroom.'),
                          );
                        }
                        return Column(
                          children: [
                            const Divider(height: 1),
                            ...fixtures.map((fix) {
                              final statusColor = _getStatusColor(fix.status);
                              return ListTile(
                                dense: true,
                                leading: Icon(_getAssetIcon(fix.name), size: 20, color: const Color(0xFF1E3A8A)),
                                title: Text(fix.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  fix.comment != null && fix.comment!.isNotEmpty
                                      ? fix.comment!
                                      : 'Status: ${fix.status}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        fix.status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.report_problem_outlined, size: 18, color: Colors.red),
                                      tooltip: 'Report fault with ${fix.name}',
                                      onPressed: () => _showReportDialog(
                                        targetLocationId: locId,
                                        targetLocationName: 'Washroom $locName',
                                        preselectedAsset: fix,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.add_comment_outlined, size: 14),
                                  label: Text('Report General Issue in $locName'),
                                  onPressed: () => _showReportDialog(
                                    targetLocationId: locId,
                                    targetLocationName: 'Washroom $locName',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildComplaintsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                  const SizedBox(height: 12),
                  const Text('No complaints logged!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('All room and floor fixtures are in working condition.', style: TextStyle(color: Colors.grey.shade600)),
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

                        // Dispute Contested Banner
                        if (c.isDisputed) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: Border.all(color: Colors.amber.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.gavel_rounded, color: Colors.purple.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assessment Contested by Resident (Pending Manager Review)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade900),
                                      ),
                                      if (c.disputeReason != null) ...[
                                        const SizedBox(height: 2),
                                        Text('Justification: "${c.disputeReason}"', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                      ],
                                      if (c.disputeResolutionNotes != null && c.disputeResolutionNotes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Manager Ruling: ${c.disputeResolutionNotes}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Ticket: ${c.displayIvrsNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            if (c.displayLocationName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text('·', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(width: 8),
                              Text(c.displayLocationName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
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

                        // Contest Assessment / Dispute Button
                        if ((c.status == 'RESOLVED' || c.status == 'CLOSED') && !c.isDisputed) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                                side: const BorderSide(color: Colors.deepOrange),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.gavel_outlined, size: 15),
                              label: const Text('Contest Assessment', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showDisputeDialog(c),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
