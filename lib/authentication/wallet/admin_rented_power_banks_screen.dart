import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RentedPowerBank {
  final String id;
  final String userId;
  final String userFullName;
  final String userPhoneNumber;
  final String planId;
  final String deviceId;
  final double planPrice;
  final DateTime rentStartTime;
  final DateTime expectedReturnTime;
  final String status;
  final String tradeNo;

  RentedPowerBank({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userPhoneNumber,
    required this.planId,
    required this.deviceId,
    required this.planPrice,
    required this.rentStartTime,
    required this.expectedReturnTime,
    required this.status,
    required this.tradeNo,
  });
}

class AdminRentedPowerBanksScreen extends StatefulWidget {
  const AdminRentedPowerBanksScreen({super.key});

  @override
  _AdminRentedPowerBanksScreenState createState() =>
      _AdminRentedPowerBanksScreenState();
}

class _AdminRentedPowerBanksScreenState
    extends State<AdminRentedPowerBanksScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 8, 151, 106),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Rented Power Banks',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 8, 151, 106),
                Color.fromARGB(255, 29, 154, 121)
              ],
            ),
          ),
        ),
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFAFBFC),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Full Name or Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: Color.fromARGB(255, 8, 151, 106)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.date_range,
                      color: Color.fromARGB(255, 8, 151, 106)),
                  onPressed: () => _selectDateRange(context),
                ),
                IconButton(
                  icon: const Icon(Icons.clear,
                      color: Color.fromARGB(255, 8, 151, 106)),
                  onPressed:
                      _selectedDateRange != null ? _clearDateRange : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return _buildErrorState(
                      'Error loading users: ${userSnapshot.error}');
                }
                if (!userSnapshot.hasData) {
                  return _buildLoadingState();
                }

                Map<String, Map<String, dynamic>> userData = {};
                for (var doc in userSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  userData[doc.id] = {
                    'fullName': data['fullName'] ?? 'Unknown',
                    'phoneNumber': data['phoneNumber'] ?? 'Unknown'
                  };
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rented_power_banks')
                      .orderBy('rentStartTime', descending: true)
                      .snapshots(),
                  builder: (context, rentedSnapshot) {
                    if (rentedSnapshot.hasError) {
                      return _buildErrorState(
                          'Error loading rentals: ${rentedSnapshot.error}');
                    }
                    if (!rentedSnapshot.hasData) {
                      return _buildLoadingState();
                    }

                    List<RentedPowerBank> allRentedPowerBanks =
                        rentedSnapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = data['userId'] ?? 'Unknown';
                      return RentedPowerBank(
                        id: doc.id,
                        userId: userId,
                        userFullName: data['userName'] ??
                            userData[userId]?['fullName'] ??
                            'Unknown',
                        userPhoneNumber: data['userPhoneNumber'] ??
                            userData[userId]?['phoneNumber'] ??
                            'Unknown',
                        planId: data['planId'] ?? 'Unknown',
                        deviceId: data['deviceId'] ?? 'Unknown',
                        planPrice: data['planPrice']?.toDouble() ?? 0.0,
                        rentStartTime:
                            (data['rentStartTime'] as Timestamp?)?.toDate() ??
                                DateTime.now(),
                        expectedReturnTime:
                            (data['expectedReturnTime'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime.now(),
                        status: data['status'] ?? 'Unknown',
                        tradeNo: data['tradeNo'] ?? 'Unknown',
                      );
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRentalList(allRentedPowerBanks, 'Today'),
                        _buildRentalList(allRentedPowerBanks, 'Yesterday'),
                        _buildRentalList(allRentedPowerBanks, 'All'),
                        _buildRentalList(allRentedPowerBanks, 'Overdue'),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color.fromARGB(255, 8, 151, 106),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Yesterday'),
          Tab(text: 'All'),
          Tab(text: 'Overdue'),
        ],
      ),
    );
  }

  Widget _buildRentalList(List<RentedPowerBank> allRentals, String tab) {
    final now = DateTime(2025, 9, 22, 13,
        29); // Current date and time: September 22, 2025, 01:29 PM EAT
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    List<RentedPowerBank> filteredList = allRentals.where((r) {
      final rentDate = DateTime(
          r.rentStartTime.year, r.rentStartTime.month, r.rentStartTime.day);
      bool matchesTab = false;
      if (_selectedDateRange != null) {
        matchesTab = rentDate.isAfter(
                _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            rentDate
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      } else {
        if (tab == 'Today') {
          matchesTab = rentDate.isAtSameMomentAs(today);
        } else if (tab == 'Yesterday') {
          matchesTab = rentDate.isAtSameMomentAs(yesterday);
        } else if (tab == 'Overdue') {
          matchesTab = r.expectedReturnTime.isBefore(now) &&
              r.status.toLowerCase() != 'returned';
        } else {
          matchesTab = true; // All tab
        }
      }
      return matchesTab &&
          (r.userFullName.toLowerCase().contains(_searchQuery) ||
              r.userPhoneNumber.toLowerCase().contains(_searchQuery));
    }).toList();

    if (filteredList.isEmpty) {
      return _buildEmptyState('No rented power banks found.');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {});
      },
      color: const Color.fromARGB(255, 8, 151, 106),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final rented = filteredList[index];
          return GestureDetector(
            onTap: () => _showRentedDialog(rented),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.battery_charging_full,
                      color: Color(0xFF10B981), size: 22),
                ),
                title: Text(
                  'Device ID: ${rented.deviceId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  '${rented.userFullName} (${rented.userPhoneNumber})\nRented: ${_formatDateTime(rented.rentStartTime)}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.battery_charging_full,
                size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Data Yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            'Error',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color.fromARGB(255, 8, 151, 106),
      ),
    );
  }

  void _showRentedDialog(RentedPowerBank rented) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Rented Power Bank Details',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogRow('User',
                    '${rented.userFullName} (${rented.userPhoneNumber})'),
                _buildDialogRow('Device ID', rented.deviceId),
                _buildDialogRow('Plan ID', rented.planId),
                _buildDialogRow('Price',
                    'TZS ${NumberFormat('#,##0').format(rented.planPrice)}'),
                _buildDialogRow(
                    'Rent Start', _formatDateTime(rented.rentStartTime)),
                _buildDialogRow('Expected Return',
                    _formatDateTime(rented.expectedReturnTime)),
                _buildDialogRow('Status', rented.status),
                _buildDialogRow('Trade No', rented.tradeNo),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                    color: Color.fromARGB(255, 8, 151, 106),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inMinutes < 5) return 'Just now';
      if (difference.inHours == 0) return '${difference.inMinutes}m ago';
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }
}
