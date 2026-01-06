import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/plan_selection_view.dart';

import '../../../../authentication/register/viewmodels/auth_viewmodel.dart';


class UpdatePlanView extends ConsumerStatefulWidget {
  const UpdatePlanView({super.key});

  @override
  ConsumerState<UpdatePlanView> createState() => _UpdatePlanViewState();
}

class _UpdatePlanViewState extends ConsumerState<UpdatePlanView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationDaysController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  Plan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planViewModelProvider.notifier).fetchPlans();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationDaysController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _populateFields(Plan plan) {
    _nameController.text = plan.name;
    _durationDaysController.text = plan.durationDays.toString();
    _priceController.text = plan.price.toString();
    _currencyController.text = plan.currency;
    setState(() {
      _selectedPlan = plan;
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PlanSelectionView()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              const Text(
                'You do not have admin privileges to update plans.',
                style: TextStyle(color: Colors.red),
              ),
            if (planState.status == PlanStatus.loading)
              const Center(child: CircularProgressIndicator()),
            if (planState.status == PlanStatus.success && planState.plans != null)
              DropdownButtonFormField<Plan>(
                value: _selectedPlan,
                decoration: const InputDecoration(labelText: 'Select Plan'),
                items: planState.plans!.map((plan) {
                  return DropdownMenuItem<Plan>(
                    value: plan,
                    child: Text(plan.name),
                  );
                }).toList(),
                onChanged: isAdmin
                    ? (plan) {
                        if (plan != null) {
                          _populateFields(plan);
                        }
                      }
                    : null,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plan Name'),
              enabled: isAdmin,
            ),
            TextField(
              controller: _durationDaysController,
              decoration: const InputDecoration(labelText: 'Duration (Days)'),
              keyboardType: TextInputType.number,
              enabled: isAdmin,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: isAdmin,
            ),
            TextField(
              controller: _currencyController,
              decoration: const InputDecoration(labelText: 'Currency (e.g., USD)'),
              enabled: isAdmin,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: planState.status == PlanStatus.loading || !isAdmin || _selectedPlan == null
                  ? null
                  : () {
                      final name = _nameController.text.trim();
                      final durationDays = int.tryParse(_durationDaysController.text.trim()) ?? 0;
                      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                      final currency = _currencyController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plan name is required')),
                        );
                        return;
                      }
                      if (durationDays <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Duration must be greater than 0')),
                        );
                        return;
                      }
                      if (price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Price must be greater than 0')),
                        );
                        return;
                      }
                      if (currency.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Currency is required')),
                        );
                        return;
                      }

                      ref.read(planViewModelProvider.notifier).updatePlan(
                            planId: _selectedPlan!.id,
                            name: name,
                            durationDays: durationDays,
                            price: price,
                            currency: currency,
                          );
                    },
              child: planState.status == PlanStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Update Plan'),
            ),
            const SizedBox(height: 16),
            if (planState.status == PlanStatus.success && planState.operationResponse != null)
              Text('Success: ${planState.operationResponse!.message}'),
            if (planState.status == PlanStatus.error && planState.errorMsg != null)
              Text('Error: ${planState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isAdmin
                  ? () {
                      ref.read(planViewModelProvider.notifier).resetState();
                      _nameController.clear();
                      _durationDaysController.clear();
                      _priceController.clear();
                      _currencyController.clear();
                      setState(() {
                        _selectedPlan = null;
                      });
                    }
                  : null,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}