import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gym_viewmodel.dart';
import '../../domain/entities/membership_plan.dart';
import '../../core/utils/validators.dart';

class MembershipPlansScreen extends StatelessWidget {
  const MembershipPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GymViewModel>(
      builder: (context, provider, child) {
        final plans = provider.membershipPlans;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membership Plans',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPlanDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Plan'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: plans.isEmpty
                    ? Center(
                        child: Text(
                          'No membership plans',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${plan.price.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plan.durationDays} days',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (plan.description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          plan.description,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditPlanDialog(
                                          context,
                                          provider,
                                          plan,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmation(
                                              context,
                                              provider,
                                              plan,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPlanDialog(BuildContext context, GymViewModel provider) {
    _showPlanDialog(context, provider, null);
  }

  void _showEditPlanDialog(
    BuildContext context,
    GymViewModel provider,
    MembershipPlan plan,
  ) {
    _showPlanDialog(context, provider, plan);
  }

  void _showPlanDialog(
    BuildContext context,
    GymViewModel provider,
    MembershipPlan? plan,
  ) {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final priceController = TextEditingController(
      text: plan?.price.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: plan?.durationDays.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: plan?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          plan == null ? 'Add Membership Plan' : 'Edit Membership Plan',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate inputs
              final nameError = Validators.validateName(nameController.text);
              final priceError = Validators.validatePrice(priceController.text);
              final durationError = Validators.validateDuration(durationController.text);

              if (nameError != null || priceError != null || durationError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(nameError ?? priceError ?? durationError ?? ''),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final price = double.parse(priceController.text);
              final duration = int.parse(durationController.text);

              final newPlan = MembershipPlan(
                id:
                    plan?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                price: price,
                durationDays: duration,
                description: descriptionController.text.trim(),
              );

              String? error;
              if (plan == null) {
                error = await provider.addMembershipPlan(newPlan);
              } else {
                error = await provider.updateMembershipPlan(newPlan);
              }

              if (error != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(plan == null
                          ? 'Plan added successfully'
                          : 'Plan updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(plan == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GymViewModel provider,
    MembershipPlan plan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete ${plan.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await provider.deleteMembershipPlan(plan.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plan deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
