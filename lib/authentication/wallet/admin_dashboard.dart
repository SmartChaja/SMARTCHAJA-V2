import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';

enum TransactionStatus { pending, completed, confirmed, failed, unknown }

TransactionStatus _stringToTransactionStatus(String? statusString) {
  if (statusString == null) return TransactionStatus.unknown;
  switch (statusString.toLowerCase()) {
    case 'pending':
      return TransactionStatus.pending;
    case 'completed':
      return TransactionStatus.completed;
    case 'confirmed':
      return TransactionStatus.confirmed;
    case 'failed':
      return TransactionStatus.failed;
    default:
      return TransactionStatus.unknown;
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String location;
  final TransactionStatus status;
  final String userId;
  final String userFullName;
  final String userPhoneNumber;
  final String msisdn;
  final String operator;
  final String externalId;
  final String transactionId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.status,
    required this.userId,
    required this.userFullName,
    required this.userPhoneNumber,
    required this.msisdn,
    required this.operator,
    required this.externalId,
    required this.transactionId,
  });
}

enum TransactionType { deposit, charge, refund }

class Plan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final int durationDays;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.durationDays,
  });
}

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

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  final Map<String, List<TransactionStatus>> _transactionCategories = {
    'All': [
      TransactionStatus.confirmed,
      TransactionStatus.completed,
      TransactionStatus.pending,
      TransactionStatus.failed,
      TransactionStatus.unknown
    ],
    'Confirmed': [TransactionStatus.confirmed, TransactionStatus.completed],
    'Pending': [TransactionStatus.pending],
    'Failed': [TransactionStatus.failed],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return _buildErrorState('Error loading users: ${userSnapshot.error}');
        }
        if (!userSnapshot.hasData) {
          return _buildLoadingState();
        }

        double totalBalance = 0.0;
        Map<String, Map<String, dynamic>> userData = {};
        totalBalance = userSnapshot.data!.docs.fold(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          userData[doc.id] = {
            'fullName': data['fullName'] ?? 'Unknown',
            'phoneNumber': data['phoneNumber'] ?? 'Unknown'
          };
          return sum + (data['balance']?.toDouble() ?? 0.0);
        });

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.hasError) {
              return _buildErrorState(
                  'Error loading transactions: ${transactionSnapshot.error}');
            }
            if (!transactionSnapshot.hasData) {
              return _buildLoadingState();
            }

            List<Transaction> allTransactions = [];
            if (transactionSnapshot.hasData) {
              allTransactions = transactionSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String description;
                TransactionType type;

                if (data['provider'] == 'Smart Chaja Wallet') {
                  description = 'Power bank usage';
                  type = TransactionType.charge;
                } else if (data['amount'] < 0 &&
                    data['provider'] != 'Smart Chaja Wallet') {
                  description = 'Refund via ${data['provider']}';
                  type = TransactionType.refund;
                } else {
                  description = 'Deposit via ${data['provider']}';
                  type = TransactionType.deposit;
                }

                final userId = data['userId'] ?? 'Unknown';
                return Transaction(
                  id: doc.id,
                  type: type,
                  amount: data['amount']?.abs()?.toDouble() ?? 0.0,
                  description: description,
                  timestamp: (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  location: data['provider'] ?? 'Unknown',
                  status: _stringToTransactionStatus(data['status']),
                  userId: userId,
                  userFullName: userData[userId]?['fullName'] ?? 'Unknown',
                  userPhoneNumber:
                      userData[userId]?['phoneNumber'] ?? 'Unknown',
                  msisdn: data['msisdn'] ?? 'Unknown',
                  operator: data['operator'] ?? 'Unknown',
                  externalId: data['externalId'] ?? 'Unknown',
                  transactionId: data['transactionId'] ?? 'Unknown',
                );
              }).toList();
            }

            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('plans').snapshots(),
              builder: (context, planSnapshot) {
                if (planSnapshot.hasError) {
                  return _buildErrorState(
                      'Error loading plans: ${planSnapshot.error}');
                }
                if (!planSnapshot.hasData) {
                  return _buildLoadingState();
                }

                List<Plan> allPlans = [];
                if (planSnapshot.hasData) {
                  allPlans = planSnapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Plan(
                      id: doc.id,
                      name: data['name'] ?? 'Unknown',
                      price: data['price']?.toDouble() ?? 0.0,
                      currency: data['currency'] ?? 'TZS',
                      durationDays: data['duration_days']?.toInt() ?? 0,
                    );
                  }).toList();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rented_power_banks')
                      .orderBy('rentStartTime', descending: true)
                      .snapshots(),
                  builder: (context, rentedSnapshot) {
                    if (rentedSnapshot.hasError) {
                      return _buildErrorState(
                          'Error loading rented power banks: ${rentedSnapshot.error}');
                    }
                    if (!rentedSnapshot.hasData) {
                      return _buildLoadingState();
                    }

                    List<RentedPowerBank> allRentedPowerBanks = [];
                    if (rentedSnapshot.hasData) {
                      allRentedPowerBanks =
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
                    }

                    return _buildMainContent(totalBalance, allTransactions,
                        allPlans, allRentedPowerBanks);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(
      double totalBalance,
      List<Transaction> allTransactions,
      List<Plan> allPlans,
      List<RentedPowerBank> allRentedPowerBanks) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 314,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderSection(totalBalance),
                ),
                automaticallyImplyLeading: false,
              ),
            ];
          },
          body: Column(
            children: [
              _buildFilterTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(
                        allTransactions, _transactionCategories['All']!),
                    _buildPlanList(allPlans),
                    _buildRentedPowerBankList(allRentedPowerBanks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double totalBalance) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildBalanceCard(totalBalance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double totalBalance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total System Balance',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TSH ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        NumberFormat('#,##0').format(totalBalance.abs()),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 24),
              ),
            ],
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
          Tab(text: 'Transactions'),
          Tab(text: 'Plans'),
          Tab(text: 'Rented Power Banks'),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> allTransactions,
      List<TransactionStatus> allowedStatuses) {
    final filteredTransactions = allTransactions
        .where((t) => allowedStatuses.contains(t.status))
        .toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState('No transactions found.');
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color.fromARGB(255, 8, 151, 106),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filteredTransactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildTransactionItem(filteredTransactions[index]),
      ),
    );
  }

  Widget _buildPlanList(List<Plan> allPlans) {
    if (allPlans.isEmpty) {
      return _buildEmptyState('No plans found.');
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color.fromARGB(255, 8, 151, 106),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: allPlans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildPlanItem(allPlans[index]),
      ),
    );
  }

  Widget _buildRentedPowerBankList(List<RentedPowerBank> allRentedPowerBanks) {
    if (allRentedPowerBanks.isEmpty) {
      return _buildEmptyState('No rented power banks found.');
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color.fromARGB(255, 8, 151, 106),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: allRentedPowerBanks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildRentedPowerBankItem(allRentedPowerBanks[index]),
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
            child: Icon(Icons.receipt_long_outlined,
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

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTransactionIcon(transaction),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User: ${transaction.userFullName} (${transaction.userPhoneNumber})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operator: ${transaction.operator}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transaction ID: ${transaction.transactionId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildAmountDisplay(transaction),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDateTime(transaction.timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(transaction.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(Plan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_membership,
                color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: ${plan.currency} ${NumberFormat('#,##0').format(plan.price)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${plan.durationDays} day${plan.durationDays == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentedPowerBankItem(RentedPowerBank rentedPowerBank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.battery_charging_full,
                    color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rented by: ${rentedPowerBank.userFullName} (${rentedPowerBank.userPhoneNumber})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Device ID: ${rentedPowerBank.deviceId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan ID: ${rentedPowerBank.planId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: TZS ${NumberFormat('#,##0').format(rentedPowerBank.planPrice)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rented: ${_formatDateTime(rentedPowerBank.rentStartTime)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Expected Return: ${_formatDateTime(rentedPowerBank.expectedReturnTime)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${rentedPowerBank.status}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Trade No: ${rentedPowerBank.tradeNo}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionIcon(Transaction transaction) {
    final config = _getTransactionConfig(transaction.type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(config.icon, color: config.color, size: 22),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
            color: config.color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAmountDisplay(Transaction transaction) {
    final config = _getTransactionConfig(transaction.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${config.prefix}${NumberFormat('#,##0').format(transaction.amount)}',
          style: TextStyle(
              color: config.color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        Text('TSH', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  TransactionConfig _getTransactionConfig(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return TransactionConfig(
            Icons.trending_up_rounded, const Color(0xFF10B981), '+');
      case TransactionType.charge:
        return TransactionConfig(
            Icons.flash_on_rounded, const Color(0xFFEF4444), '-');
      case TransactionType.refund:
        return TransactionConfig(
            Icons.refresh_rounded, const Color(0xFF3B82F6), '+');
    }
  }

  StatusConfig _getStatusConfig(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
      case TransactionStatus.completed:
        return StatusConfig(const Color(0xFF10B981), 'Completed');
      case TransactionStatus.pending:
        return StatusConfig(const Color(0xFFF59E0B), 'Pending');
      case TransactionStatus.failed:
        return StatusConfig(const Color(0xFFEF4444), 'Failed');
      default:
        return StatusConfig(Colors.grey, 'Unknown');
    }
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

class TransactionConfig {
  final IconData icon;
  final Color color;
  final String prefix;

  TransactionConfig(this.icon, this.color, this.prefix);
}

class StatusConfig {
  final Color color;
  final String label;

  StatusConfig(this.color, this.label);
}
