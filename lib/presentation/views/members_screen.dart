import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xboost_system/core/utils/validators.dart';
import '../viewmodels/gym_viewmodel.dart';
import '../../domain/entities/member.dart';

class MembersScreen extends StatefulWidget {
  final bool autoOpenAddDialog;
  final VoidCallback? onDialogOpened;
  final int? initialTabIndex;

  const MembersScreen({
    super.key,
    this.autoOpenAddDialog = false,
    this.onDialogOpened,
    this.initialTabIndex,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasOpenedDialog = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex.clamp(0, 2),
    );

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent -
              _scrollController.position.pixels <=
          200) {
        final provider = Provider.of<GymViewModel>(context, listen: false);
        if (!provider.isLoadingMembers && provider.hasMoreMembers) {
          provider.loadMoreMembers();
        }
      }
    });

    if (widget.autoOpenAddDialog && !_hasOpenedDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.autoOpenAddDialog && !_hasOpenedDialog) {
          final provider = Provider.of<GymViewModel>(context, listen: false);
          _hasOpenedDialog = true;
          _showAddMemberDialog(context, provider);
          widget.onDialogOpened?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(MembersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle tab index change
    if (widget.initialTabIndex != null &&
        widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != _tabController.index) {
      _tabController.animateTo(widget.initialTabIndex!);
    }

    if (widget.autoOpenAddDialog &&
        !oldWidget.autoOpenAddDialog &&
        !_hasOpenedDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.autoOpenAddDialog && !_hasOpenedDialog) {
          final provider = Provider.of<GymViewModel>(context, listen: false);
          _hasOpenedDialog = true;
          _showAddMemberDialog(context, provider);
          widget.onDialogOpened?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Member> _getExpiredOrUnpaidMembers(List<Member> allMembers) {
    final now = DateTime.now();
    return allMembers.where((member) {
      // Member is expired if expiryDate is in the past
      final isExpired =
          member.expiryDate != null && member.expiryDate!.isBefore(now);
      // Member is inactive (hasn't paid or deactivated)
      final isInactive = !member.isActive;
      return isExpired || isInactive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GymViewModel>(
      builder: (context, provider, child) {
        final allMembers = provider.members;
        final expiredOrUnpaidMembers = _getExpiredOrUnpaidMembers(allMembers);
        final expiringSoonMembers = provider.getExpiringSoonMembers();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMemberDialog(context, provider),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All Members'),
                  Tab(text: 'Expired/Unpaid'),
                  Tab(text: 'Expiring Soon'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMembersList(allMembers, provider),
                    _buildMembersList(expiredOrUnpaidMembers, provider),
                    _buildMembersList(expiringSoonMembers, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersList(List<Member> members, GymViewModel provider) {
    final filteredMembers = _searchController.text.isEmpty
        ? members
        : members.where((m) {
            final query = _searchController.text.toLowerCase();
            return m.name.toLowerCase().contains(query) ||
                m.email.toLowerCase().contains(query) ||
                m.phone.contains(query);
          }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
        child: Text(
          'No members found',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount:
          filteredMembers.length +
          (provider.hasMoreMembers && _tabController.index == 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredMembers.length) {
          // Loading indicator at bottom
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: provider.isLoadingMembers
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        final member = filteredMembers[index];
        final plan = provider.getMembershipPlanById(member.membershipPlanId);
        final now = DateTime.now();
        final isExpired =
            member.expiryDate != null && member.expiryDate!.isBefore(now);
        final isExpiringSoon =
            member.expiryDate != null &&
            member.isActive &&
            !isExpired &&
            member.expiryDate!.isAfter(now) &&
            member.expiryDate!.difference(now).inDays <= 7;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: member.isActive && !isExpired
                  ? (isExpiringSoon ? Colors.amber : Colors.green)
                  : Colors.red,
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.email,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  member.phone,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (plan != null)
                  Text(
                    'Plan: ${plan.name}',
                    style: TextStyle(color: Colors.blue[700]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (member.expiryDate != null)
                  Builder(
                    builder: (context) {
                      final daysLeft = member.daysLeft;
                      final daysText = daysLeft == null
                          ? ''
                          : (daysLeft >= 0
                                ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left'
                                : 'Expired');

                      return Row(
                        children: [
                          if (isExpiringSoon)
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                          if (isExpiringSoon) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Expires: ${DateFormat('MMM dd, yyyy').format(member.expiryDate!)}${daysText.isNotEmpty ? ' • $daysText' : ''}',
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.red
                                    : isExpiringSoon
                                    ? Colors.amber[700]
                                    : Colors.grey[600],
                                fontWeight: (isExpired || isExpiringSoon)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  Text(
                    'No expiry date set',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!member.isActive)
                  Text(
                    'Inactive',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'View QR Code',
                  onPressed: () => _showQRCodeDialog(context, member, provider),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditMemberDialog(context, provider, member),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmation(context, provider, member),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, GymViewModel provider) {
    _showMemberDialog(context, provider, null);
  }

  void _showEditMemberDialog(
    BuildContext context,
    GymViewModel provider,
    Member member,
  ) {
    _showMemberDialog(context, provider, member);
  }

  void _showMemberDialog(
    BuildContext context,
    GymViewModel provider,
    Member? member,
  ) {
    final nameController = TextEditingController(text: member?.name ?? '');
    final emailController = TextEditingController(text: member?.email ?? '');
    final phoneController = TextEditingController(text: member?.phone ?? '');
    String? selectedPlanId =
        member?.membershipPlanId ?? provider.membershipPlans.firstOrNull?.id;
    DateTime joinDate = member?.joinDate ?? DateTime.now();
    DateTime? expiryDate = member?.expiryDate;

    // If adding a new member and a plan is preselected, compute expiry from joinDate
    if (member == null && selectedPlanId != null) {
      final plan = provider.getMembershipPlanById(selectedPlanId);
      if (plan != null) {
        expiryDate = joinDate.add(Duration(days: plan.durationDays));
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(member == null ? 'Add Member' : 'Edit Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Join Date (From)
                ListTile(
                  title: Text(
                    'From: ${DateFormat('MMM dd, yyyy').format(joinDate)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: joinDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 3650),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          joinDate = picked;
                          // Recompute expiry if plan selected
                          if (selectedPlanId != null) {
                            final plan = provider.getMembershipPlanById(
                              selectedPlanId!,
                            );
                            if (plan != null) {
                              expiryDate = joinDate.add(
                                Duration(days: plan.durationDays),
                              );
                            }
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlanId,
                  decoration: const InputDecoration(
                    labelText: 'Membership Plan',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.membershipPlans.map((plan) {
                    return DropdownMenuItem(
                      value: plan.id,
                      child: Text(
                        '${plan.name} - \$${plan.price.toStringAsFixed(2)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlanId = value;
                      final plan = value != null
                          ? provider.getMembershipPlanById(value)
                          : null;
                      if (plan != null) {
                        expiryDate = joinDate.add(
                          Duration(days: plan.durationDays),
                        );
                      }
                    });
                  },
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Expiry Date: ${DateFormat('MMM dd, yyyy').format(expiryDate!)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            expiryDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
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
                final emailError = Validators.validateEmail(
                  emailController.text,
                );
                final phoneError = Validators.validatePhone(
                  phoneController.text,
                );

                if (nameError != null ||
                    emailError != null ||
                    phoneError != null ||
                    selectedPlanId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nameError ??
                            emailError ??
                            phoneError ??
                            'Please select a membership plan',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newMember = Member(
                  id:
                      member?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  membershipPlanId: selectedPlanId!,
                  joinDate: joinDate,
                  expiryDate: expiryDate,
                  isActive: member?.isActive ?? true,
                );

                String? error;
                if (member == null) {
                  error = await provider.addMember(newMember);
                } else {
                  error = await provider.updateMember(newMember);
                }

                if (error != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          member == null
                              ? 'Member added successfully'
                              : 'Member updated successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text(member == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GymViewModel provider,
    Member member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
          'Are you sure you want to delete ${member.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await provider.deleteMember(member.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member deleted successfully'),
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

  void _showQRCodeDialog(
    BuildContext context,
    Member member,
    GymViewModel provider,
  ) {
    final plan = provider.getMembershipPlanById(member.membershipPlanId);
    // Create QR code data with member information
    final daysLeft = member.daysLeft;
    final qrData = {
      'id': member.id,
      'name': member.name,
      'email': member.email,
      'phone': member.phone,
      'plan': plan?.name ?? 'Unknown',
      'expiry': member.expiryDate?.toIso8601String() ?? '',
      'daysLeft': daysLeft,
      'status': member.isExpired ? 'Expired' : 'Active',
    };
    // JSON payload (machine-friendly) and a human-readable summary for quick viewing on phone.
    final qrDataString = qrData.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Member QR Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(member.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: qrDataString,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 12),
              if (plan != null)
                Text(
                  'Plan: ${plan.name}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              if (member.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(member.expiryDate!)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
