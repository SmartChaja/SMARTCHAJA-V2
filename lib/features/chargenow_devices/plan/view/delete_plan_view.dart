import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan_state.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/provider/plan_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/view/plan_selection_view.dart';

import '../../../../authentication/register/viewmodels/auth_viewmodel.dart';


class DeletePlanView extends ConsumerStatefulWidget {
  const DeletePlanView({super.key});

  @override
  ConsumerState<DeletePlanView> createState() => _DeletePlanViewState();
}

class _DeletePlanViewState extends ConsumerState<DeletePlanView> {
  Plan? _selectedPlan;

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
        title: const Text('Delete Plan'),
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
                'You do not have admin privileges to delete plans.',
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
                        setState(() {
                          _selectedPlan = plan;
                        });
                      }
                    : null,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: planState.status == PlanStatus.loading || !isAdmin || _selectedPlan == null
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete ${_selectedPlan!.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(planViewModelProvider.notifier).deletePlan(_selectedPlan!.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
              child: planState.status == PlanStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Delete Plan'),
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