import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  _AdminTransactionsScreenState createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState
    extends ConsumerState<AdminTransactionsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Transactions',
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
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return _buildErrorState(
                'Error loading users: ${userSnapshot.error}');
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
            final balance = data['balance']?.toDouble() ?? 0.0;
            return balance >= 0 ? sum + balance : sum;
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

              return Column(
                children: [
                  const SizedBox(height: 16),
                  _buildBalanceCard(totalBalance),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  const SizedBox(height: 16),
                  _buildFilterTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionList(
                            allTransactions, _transactionCategories['All']!),
                        _buildTransactionList(allTransactions,
                            _transactionCategories['Confirmed']!),
                        _buildTransactionList(allTransactions,
                            _transactionCategories['Pending']!),
                        _buildTransactionList(
                            allTransactions, _transactionCategories['Failed']!),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double totalBalance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 8, 151, 106),
            Color.fromARGB(255, 29, 154, 121)
          ],
        ),
      ),
      child: Row(
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
                        fontSize: 24,
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
                color: Color.fromARGB(255, 255, 255, 255), size: 24),
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
          Tab(text: 'All'),
          Tab(text: 'Confirmed'),
          Tab(text: 'Pending'),
          Tab(text: 'Failed'),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> allTransactions,
      List<TransactionStatus> allowedStatuses) {
    final filteredTransactions = allTransactions
        .where((t) =>
            allowedStatuses.contains(t.status) &&
            (t.userFullName.toLowerCase().contains(_searchQuery) ||
                t.userPhoneNumber.toLowerCase().contains(_searchQuery)))
        .toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState('No transactions found.');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {});
      },
      color: const Color.fromARGB(255, 8, 151, 106),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return GestureDetector(
            onTap: () => _showTransactionDialog(transaction),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildTransactionIcon(transaction),
                title: Text(
                  transaction.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  '${transaction.userFullName} (${transaction.userPhoneNumber})\n${_formatDateTime(transaction.timestamp)}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                trailing: _buildAmountDisplay(transaction),
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

  void _showTransactionDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Transaction Details',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogRow('Description', transaction.description),
                _buildDialogRow('User',
                    '${transaction.userFullName} (${transaction.userPhoneNumber})'),
                _buildDialogRow('Amount',
                    'TSH ${NumberFormat('#,##0').format(transaction.amount)}'),
                _buildDialogRow('Date', _formatDateTime(transaction.timestamp)),
                _buildDialogRow(
                    'Status', _getStatusConfig(transaction.status).label),
                _buildDialogRow('Operator', transaction.operator),
                _buildDialogRow('MSISDN', transaction.msisdn),
                _buildDialogRow('External ID', transaction.externalId),
                _buildDialogRow('Transaction ID', transaction.transactionId),
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
