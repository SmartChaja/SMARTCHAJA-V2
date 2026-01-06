import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/create_plan_view.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/delete_plan_view.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/update_plan_view.dart';

import '../../../../authentication/register/viewmodels/auth_viewmodel.dart';



class PlanSelectionView extends ConsumerStatefulWidget {
  const PlanSelectionView({super.key});

  @override
  ConsumerState<PlanSelectionView> createState() => _PlanSelectionViewState();
}

class _PlanSelectionViewState extends ConsumerState<PlanSelectionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planViewModelProvider.notifier).fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Plan'),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreatePlanView()),
                    );
                  },
                  tooltip: 'Create Plan',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UpdatePlanView()),
                    );
                  },
                  tooltip: 'Update Plan',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeletePlanView()),
                    );
                  },
                  tooltip: 'Delete Plan',
                ),
              ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (planState.status == PlanStatus.loading)
              const Center(child: CircularProgressIndicator()),
            if (planState.status == PlanStatus.success && planState.plans != null)
              Expanded(
                child: planState.plans!.isEmpty
                    ? const Center(child: Text('No plans available'))
                    : ListView.builder(
                        itemCount: planState.plans!.length,
                        itemBuilder: (context, index) {
                          final plan = planState.plans![index];
                          final isSelected = planState.selectedPlan?.id == plan.id;
                          return Card(
                            color: isSelected ? Colors.blue[100] : null,
                            child: ListTile(
                              title: Text(plan.name),
                              subtitle: Text(
                                  '${plan.durationDays} day${plan.durationDays > 1 ? 's' : ''} - ${plan.price.toStringAsFixed(2)} ${plan.currency}'),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                              onTap: () {
                                ref.read(planViewModelProvider.notifier).selectPlan(plan);
                              },
                            ),
                          );
                        },
                      ),
              ),
            if (planState.status == PlanStatus.error && planState.errorMsg != null)
              Text('Error: ${planState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: planState.selectedPlan == null ||
                      planState.status == PlanStatus.loading
                  ? null
                  : () {
                      // Navigate to CreateRentOrderView or perform order creation
                      final selectedPlan = planState.selectedPlan!;
                      print('Selected Plan: ${selectedPlan.name}, ${selectedPlan.price} ${selectedPlan.currency}');
                      // TODO: Navigate to CreateRentOrderView with selectedPlan
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRentOrderView(plan: selectedPlan)));
                    },
              child: const Text('Proceed to Order'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(planViewModelProvider.notifier).resetState();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}