import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/gym_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToMembers;
  final VoidCallback? onNavigateToCheckIn;
  final VoidCallback? onNavigateToPlans;
  final VoidCallback? onNavigateToExpiredUnpaid;
  final VoidCallback? onNavigateToExpiringSoon;

  const DashboardScreen({
    super.key,
    this.onNavigateToMembers,
    this.onNavigateToCheckIn,
    this.onNavigateToPlans,
    this.onNavigateToExpiredUnpaid,
    this.onNavigateToExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GymViewModel>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App logo
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SvgPicture.asset(
                          'assets/icons/xboost_logo.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [_EgyptClock()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Members',
                      value: provider.totalMembers.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: onNavigateToMembers,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Active Members',
                      value: provider.activeMembers.toString(),
                      icon: Icons.verified_user,
                      color: Colors.green,
                      onTap: onNavigateToMembers,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Checked In',
                      value: provider.checkedInCount.toString(),
                      icon: Icons.login,
                      color: Colors.orange,
                      onTap: onNavigateToCheckIn,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Today\'s Check-ins',
                      value: provider.getTodayCheckIns().toString(),
                      icon: Icons.today,
                      color: Colors.purple,
                      onTap: onNavigateToCheckIn,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Expired/Unpaid',
                      value: provider.expiredOrUnpaidMembersCount.toString(),
                      icon: Icons.warning,
                      color: Colors.red,
                      onTap: onNavigateToExpiredUnpaid,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Expiring Soon',
                      value: provider.expiringSoonMembersCount.toString(),
                      icon: Icons.schedule,
                      color: Colors.amber,
                      onTap: onNavigateToExpiringSoon,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Membership Plans',
                      value: provider.membershipPlans.length.toString(),
                      icon: Icons.card_membership,
                      color: Colors.teal,
                      onTap: onNavigateToPlans,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _RecentCheckIns(provider: provider),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _QuickActions(
                        onNavigateToMembers: onNavigateToMembers,
                        onNavigateToCheckIn: onNavigateToCheckIn,
                        onNavigateToPlans: onNavigateToPlans,
                        provider: provider,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
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

class _RecentCheckIns extends StatelessWidget {
  final GymViewModel provider;

  const _RecentCheckIns({required this.provider});

  @override
  Widget build(BuildContext context) {
    final activeCheckIns = provider.activeCheckIns;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently Checked In',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: activeCheckIns.isEmpty
                  ? Center(
                      child: Text(
                        'No active check-ins',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeCheckIns.length,
                      itemBuilder: (context, index) {
                        final checkIn = activeCheckIns[index];
                        final member = provider.getMemberByIdSync(
                          checkIn.memberId,
                        );
                        if (member == null) return const SizedBox.shrink();

                        final duration = DateTime.now().difference(
                          checkIn.checkInTime,
                        );
                        final hours = duration.inHours;
                        final minutes = duration.inMinutes % 60;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(member.name),
                          subtitle: Text(
                            'Checked in at ${DateFormat('hh:mm a').format(checkIn.checkInTime)}',
                          ),
                          trailing: Text(
                            '${hours}h ${minutes}m',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showExportDialog(BuildContext context) {
  final provider = Provider.of<GymViewModel>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Export Members'),
            subtitle: const Text('Export all members to CSV'),
            onTap: () async {
              Navigator.pop(context);
              final path = await provider.exportMembersToCSV();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(path != null
                        ? 'Members exported to: $path'
                        : 'Failed to export members'),
                    backgroundColor: path != null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Export Plans'),
            subtitle: const Text('Export all membership plans to CSV'),
            onTap: () async {
              Navigator.pop(context);
              final path = await provider.exportPlansToCSV();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(path != null
                        ? 'Plans exported to: $path'
                        : 'Failed to export plans'),
                    backgroundColor: path != null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Export Check-ins'),
            subtitle: const Text('Export all check-ins to CSV'),
            onTap: () async {
              Navigator.pop(context);
              final path = await provider.exportCheckInsToCSV();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(path != null
                        ? 'Check-ins exported to: $path'
                        : 'Failed to export check-ins'),
                    backgroundColor: path != null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  final VoidCallback? onNavigateToMembers;
  final VoidCallback? onNavigateToCheckIn;
  final VoidCallback? onNavigateToPlans;
  final GymViewModel provider;

  const _QuickActions({
    this.onNavigateToMembers,
    this.onNavigateToCheckIn,
    this.onNavigateToPlans,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _ActionButton(
                    icon: Icons.person_add,
                    label: 'Add Member',
                    onTap: () {
                      onNavigateToMembers?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.login,
                    label: 'Check In',
                    onTap: () {
                      onNavigateToCheckIn?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.card_membership,
                    label: 'Membership Plans',
                    onTap: () {
                      onNavigateToPlans?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.download,
                    label: 'Export Data',
                    onTap: () => _showExportDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.format_paint,
                    label: 'Theme',
                    onTap: () async {
                      final theme = Provider.of<ThemeViewModel>(
                        context,
                        listen: false,
                      );
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Select Theme'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<AppTheme>(
                                title: Row(
                                  children: const [
                                    Icon(Icons.male, size: 20),
                                    SizedBox(width: 8),
                                    Text('Man'),
                                  ],
                                ),
                                value: AppTheme.men,
                                groupValue: theme.current,
                                onChanged: (v) {
                                  if (v != null) theme.setTheme(v);
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile<AppTheme>(
                                title: Row(
                                  children: const [
                                    Icon(Icons.female, size: 20),
                                    SizedBox(width: 8),
                                    Text('Girl'),
                                  ],
                                ),
                                value: AppTheme.girls,
                                groupValue: theme.current,
                                onChanged: (v) {
                                  if (v != null) theme.setTheme(v);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _EgyptClock extends StatefulWidget {
  @override
  State<_EgyptClock> createState() => _EgyptClockState();
}

class _EgyptClockState extends State<_EgyptClock> {
  Timer? _timer;
  DateTime _egyptTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    // Egypt is UTC+2 (Cairo timezone)
    final utcNow = DateTime.now().toUtc();
    final egyptTime = utcNow.add(const Duration(hours: 2));
    setState(() {
      _egyptTime = egyptTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Egypt Time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm:ss a').format(_egyptTime),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            Text(
              DateFormat('EEEE, MMM dd, yyyy').format(_egyptTime),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
