import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_wave_header.dart';
class AuthorityComplaintsScreen extends StatefulWidget {
  const AuthorityComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<AuthorityComplaintsScreen> createState() => _AuthorityComplaintsScreenState();
}

class _AuthorityComplaintsScreenState extends State<AuthorityComplaintsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedCategoryFilter = 'All Activities';

  final List<String> _filterOptions = ['All', 'Pending', 'Reviewed', 'Action Taken', 'Dismissed'];
  final List<String> _categoryOptions = [
    'All Activities',
    'Fishing in Banned Area',
    'Fishing During Ban Season',
    'Using Illegal Small Nets',
    'Suspicious Night Fishing',
    'Dumping Trash or Oil'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageBanner(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildComplaintStatsRow(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCategoryChips(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No incident reports found.', 
                      style: TextStyle(fontSize: 16, color: Colors.grey)
                    ),
                  );
                }

                // Apply Filters and Search
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchesFilter = _selectedFilter == 'All' || (data['status'] ?? 'Pending') == _selectedFilter;
                  
                  bool matchesCategory = true;
                  if (_selectedCategoryFilter != 'All Activities') {
                    final activity = (data['activityType'] ?? '').toString();
                    matchesCategory = activity.contains(_selectedCategoryFilter);
                  }

                  if (!matchesFilter || !matchesCategory) return false;

                  if (_searchQuery.isEmpty) return true;

                  String searchLower = _searchQuery.toLowerCase();
                  String activity = (data['activityType'] ?? '').toString().toLowerCase();
                  String vessel = (data['vesselType'] ?? '').toString().toLowerCase();
                  String reporter = (data['reporterName'] ?? '').toString().toLowerCase();

                  return activity.contains(searchLower) || vessel.contains(searchLower) || reporter.contains(searchLower);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No reports match your search criteria.', 
                      style: TextStyle(fontSize: 16, color: Colors.grey)
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 150),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildComplaintCard(context, doc.id, data);
                  },
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 24),
      child: Text(
        'Complaint Reports',
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by Activity, Vessel, or Reporter...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildComplaintStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int pending = 0;
        int reviewed = 0;
        int actionTaken = 0;
        int dismissed = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            if (status == 'Pending') pending++;
            if (status == 'Reviewed') reviewed++;
            if (status == 'Action Taken') actionTaken++;
            if (status == 'Dismissed') dismissed++;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMiniStat('Total', total, Colors.black87),
                _buildDivider(),
                _buildMiniStat('Pending', pending, Colors.orange),
                _buildDivider(),
                _buildMiniStat('Reviewed', reviewed, Colors.blue),
                _buildDivider(),
                _buildMiniStat('Action Taken', actionTaken, Colors.green),
                _buildDivider(),
                _buildMiniStat('Dismissed', dismissed, Colors.grey.shade700),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildMiniStat(String title, int value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterOptions.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryOptions.map((filter) {
          bool isSelected = _selectedCategoryFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple.shade700 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedCategoryFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.deepPurple.shade50,
              checkmarkColor: Colors.deepPurple.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.deepPurple.shade300 : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, String docId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    Color statusColor = _getStatusColor(status);
    
    DateTime? reportedDate;
    if (data['timestamp'] != null) {
      reportedDate = (data['timestamp'] as Timestamp).toDate();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showComplaintDetails(context, docId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (data['aiAnalysis'] != null && data['aiAnalysis']['priority'] != null)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(data['aiAnalysis']['priority']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getPriorityColor(data['aiAnalysis']['priority'])),
                            ),
                            child: Text(
                              data['aiAnalysis']['priority'].toString().toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(data['aiAnalysis']['priority']),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            data['activityType'] ?? 'Unknown Activity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vessel: ${data['vesselType'] ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Reported by: ${data['reporterName'] ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              if (data['reporterPhone'] != null && data['reporterPhone'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Contact: ${data['reporterPhone']}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
              if (reportedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(reportedDate)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Reviewed':
        return Colors.blue;
      case 'Action Taken':
        return Colors.green;
      case 'Dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pending':
        return 'This report has been received and is waiting for an initial review by the authorities.';
      case 'Reviewed':
        return 'This report has been reviewed. An investigation is currently being planned or is underway.';
      case 'Action Taken':
        return 'Authorities have investigated and taken necessary action regarding this report.';
      case 'Dismissed':
        return 'This report was reviewed but found to lack sufficient evidence or was a false alarm.';
      default:
        return 'Status unknown.';
    }
  }

  void _showComplaintDetails(BuildContext context, String docId, Map<String, dynamic> data) {
    Widget buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
            Expanded(child: Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wraps to fit content height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Incident Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(10),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    panEnabled: true,
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: !_isNetworkUrl(data['imageUrl']?.toString())
                                        ? (_getBytesFromBase64(data['imageUrl']?.toString()) != null
                                            ? Image.memory(_getBytesFromBase64(data['imageUrl']!.toString())!, fit: BoxFit.contain)
                                            : const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white24)))
                                        : Image.network(data['imageUrl'].toString(), fit: BoxFit.contain),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: !_isNetworkUrl(data['imageUrl']?.toString())
                            ? (_getBytesFromBase64(data['imageUrl']?.toString()) != null
                                ? Image.memory(
                                    _getBytesFromBase64(data['imageUrl']!.toString())!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 200,
                                    color: AppColors.cardLight,
                                    child: Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.textMuted)),
                                  ))
                            : Image.network(
                                data['imageUrl'].toString(),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  color: AppColors.cardLight,
                                  child: Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.textMuted)),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        height: 140, // Perfectly adjusted framed box
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 36, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'No photo provided for this report',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (data['audioUrl'] != null && data['audioUrl'].toString().isNotEmpty) ...[
                      Text(
                        'Voice Evidence',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      _AudioPlayerWidget(audioData: data['audioUrl']),
                      const SizedBox(height: 20),
                    ],

                    Text(
                      'Activity Type: ${data['activityType'] ?? 'N/A'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vessel Type: ${data['vesselType'] ?? 'N/A'}',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? 'No description provided.',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Location Coordinates',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    if (data['location'] != null) ...[
                      if (data['locationName'] != null) ...[
                        Text(
                          '${data['locationName']}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Lat: ${(data['location'] as GeoPoint).latitude}',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                      Text(
                        'Lng: ${(data['location'] as GeoPoint).longitude}',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ] else ...[
                      Text(
                        'Not available',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 24),

                    if (data['aiAnalysis'] != null) ...[
                      Text(
                        'AI & GIS Analysis',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Priority: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                                Text(
                                  '${data['aiAnalysis']['priority']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getPriorityColor(data['aiAnalysis']['priority'] as String?),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            buildInfoRow('Category', data['aiAnalysis']['category']?.toString() ?? 'N/A'),
                            buildInfoRow('Hotspot', data['aiAnalysis']['isHotspot'] == true ? "Yes" : "No"),
                            buildInfoRow('PFZ Status', data['aiAnalysis']['pfzProximity']?.toString() ?? data['aiAnalysis']['pfzStatus']?.toString() ?? 'N/A'),
                            buildInfoRow('CRZ Violation', data['aiAnalysis']['crzViolation'] == true ? "Yes" : "No"),
                            const SizedBox(height: 8),
                            Divider(color: AppColors.border),
                            const SizedBox(height: 8),
                            Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${data['aiAnalysis']['summary']}',
                              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Update Status Section
                    Text(
                      'Update Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['Pending', 'Reviewed', 'Action Taken', 'Dismissed'].map((status) {
                        bool isSelected = data['status'] == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              if (status == 'Action Taken' || status == 'Dismissed') {
                                _showProofOfActionDialog(context, docId, status, data);
                              } else {
                                FirebaseFirestore.instance.collection('complaints').doc(docId).update({'status': status});
                                Navigator.pop(context); // Close modal on update
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data['status'] ?? 'Pending').withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(data['status'] ?? 'Pending').withOpacity(0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: _getStatusColor(data['status'] ?? 'Pending'), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getStatusDescription(data['status'] ?? 'Pending'),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showProofOfActionDialog(BuildContext context, String docId, String newStatus, Map<String, dynamic> data) {
    final TextEditingController proofController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proof of $newStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide details or proof of the action taken (or reason for dismissal) before updating the status:'),
            const SizedBox(height: 12),
            TextField(
              controller: proofController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter proof/reason here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (proofController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proof of action is required.')));
                return;
              }
              
              // Build acknowledgement message
              final reporterName = data['originalFarmerName'] ?? data['reporterName'] ?? 'Citizen';
              final String acknowledgementMessage = "Dear $reporterName, your complaint about ${data['activityType']} has been marked as '$newStatus'. Details: ${proofController.text.trim()} - Maritime Authority";

              // Update status, proof, and acknowledgement message
              await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
                'status': newStatus,
                'proofOfAction': proofController.text.trim(),
                'statusUpdatedAt': FieldValue.serverTimestamp(),
                'acknowledgementMessage': acknowledgementMessage,
              });
              
              if(context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close modal
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus and farmer notified in-app.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _getStatusColor(newStatus), foregroundColor: Colors.white),
            child: const Text('Update & Notify'),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String audioData;
  const _AudioPlayerWidget({Key? key, required this.audioData}) : super(key: key);

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        if (widget.audioData.startsWith('data:audio')) {
           final String base64Str = widget.audioData.split(',').last.replaceAll(RegExp(r'\s+'), '');
           final bytes = base64Decode(base64Str);
           await _audioPlayer.play(BytesSource(bytes));
        } else {
           await _audioPlayer.play(UrlSource(widget.audioData));
        }
      } catch (e) {
        print("Error playing audio evidence: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.primary,
              ),
              onPressed: _togglePlay,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPlaying ? 'Playing Audio...' : 'Voice Evidence Attached',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap to listen to the farmer\'s recording.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isNetworkUrl(String? url) {
  if (url == null) return false;
  return url.startsWith('http://') || url.startsWith('https://');
}

Uint8List? _getBytesFromBase64(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    String cleanStr = base64Str.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleanStr.startsWith('data:')) {
      cleanStr = cleanStr.split(',').last;
    }
    return base64Decode(cleanStr);
  } catch (e) {
    print("Error decoding base64 image: $e");
    return null;
  }
}
