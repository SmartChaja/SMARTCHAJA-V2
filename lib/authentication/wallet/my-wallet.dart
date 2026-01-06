import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;
  final _tabs = ['All', 'Completed', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return _AuthRequiredView();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snap) {
            final balance =
                (snap.data?.data() as Map<String, dynamic>?)?['balance']
                        ?.toDouble() ??
                    0.0;
            return Column(
              children: [
                _Header(balance: balance),
                _QuickActions(),
                _TabSection(controller: _tabController, tabs: _tabs),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs
                        .map((t) =>
                            _TransactionList(userId: user.uid, filter: t))
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthRequiredView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wallet_outlined,
                    size: 40, color: Color(0xFF0D9488)),
              ),
              const SizedBox(height: 24),
              const Text('Sign in Required',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Please sign in to access your wallet',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double balance;
  const _Header({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallet',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance >= 0 ? 'Available Balance' : 'Outstanding',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TSH ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    Text(
                      NumberFormat('#,##0').format(balance.abs()),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
              child: _ActionBtn(
                  icon: Icons.add,
                  label: 'Add Money',
                  onTap: () => Navigator.pushNamed(context, '/payment'))),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionBtn(
                  icon: Icons.history,
                  label: 'Refund',
                  onTap: () => _showSnack(context, 'Refund coming soon'))),
        ],
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0D9488)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSection extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  const _TabSection({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(8)),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final String userId;
  final String filter;
  const _TransactionList({required this.userId, required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)));
        }

        final txs = snap.data!.docs
            .map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _TxData.fromMap(d.id, data);
            })
            .where((t) => _matchesFilter(t.status, filter))
            .toList();

        if (txs.isEmpty) return _EmptyState();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TxCard(tx: txs[i]),
        );
      },
    );
  }

  bool _matchesFilter(String status, String filter) {
    if (filter == 'All') return true;
    if (filter == 'Completed') {
      return status == 'completed' || status == 'confirmed';
    }
    return status.toLowerCase() == filter.toLowerCase();
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No transactions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 4),
          Text('Your activity will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final _TxData tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final cfg = _getConfig(tx.type);
    final statusCfg = _getStatusCfg(tx.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: cfg.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(cfg.icon, color: cfg.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.desc,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatTime(tx.time),
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: statusCfg.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(statusCfg.label,
                          style: TextStyle(
                              color: statusCfg.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${cfg.prefix}${NumberFormat('#,##0').format(tx.amount)}',
                  style: TextStyle(
                      color: cfg.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text('TSH',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  _TxConfig _getConfig(String type) {
    switch (type) {
      case 'deposit':
        return _TxConfig(
            Icons.arrow_downward_rounded, const Color(0xFF10B981), '+');
      case 'charge':
        return _TxConfig(Icons.bolt_rounded, const Color(0xFFEF4444), '-');
      case 'refund':
        return _TxConfig(Icons.refresh_rounded, const Color(0xFF3B82F6), '+');
      default:
        return _TxConfig(Icons.swap_horiz, Colors.grey, '');
    }
  }

  _StatusCfg _getStatusCfg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
        return _StatusCfg(const Color(0xFF10B981), 'Done');
      case 'pending':
        return _StatusCfg(const Color(0xFFF59E0B), 'Pending');
      case 'failed':
        return _StatusCfg(const Color(0xFFEF4444), 'Failed');
      default:
        return _StatusCfg(Colors.grey, 'Unknown');
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}

class _TxData {
  final String id, type, desc, status;
  final double amount;
  final DateTime time;

  _TxData(
      {required this.id,
      required this.type,
      required this.amount,
      required this.desc,
      required this.time,
      required this.status});

  factory _TxData.fromMap(String id, Map<String, dynamic> m) {
    final provider = m['provider'] ?? '';
    final amt = (m['amount'] ?? 0).toDouble();
    String type, desc;

    if (provider == 'Smart Chaja Wallet') {
      type = 'charge';
      desc = 'Power bank usage';
    } else if (amt < 0) {
      type = 'refund';
      desc = 'Refund via $provider';
    } else {
      type = 'deposit';
      desc = 'Deposit via $provider';
    }

    return _TxData(
      id: id,
      type: type,
      amount: amt.abs(),
      desc: desc,
      time: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: m['status'] ?? 'unknown',
    );
  }
}

class _TxConfig {
  final IconData icon;
  final Color color;
  final String prefix;
  _TxConfig(this.icon, this.color, this.prefix);
}

class _StatusCfg {
  final Color color;
  final String label;
  _StatusCfg(this.color, this.label);
}
