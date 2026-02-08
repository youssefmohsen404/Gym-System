import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/gym_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, provider, child) {
        final members = provider.members.where((m) => m.isActive).toList();
        final filteredMembers = _searchController.text.isEmpty
            ? members
            : members.where((m) {
                final query = _searchController.text.toLowerCase();
                return m.name.toLowerCase().contains(query) ||
                    m.email.toLowerCase().contains(query) ||
                    m.phone.contains(query);
              }).toList();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check In / Check Out',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
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
                child: filteredMembers.isEmpty
                    ? Center(
                        child: Text(
                          'No members found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final isCheckedIn = provider.isMemberCheckedIn(
                            member.id,
                          );
                          final activeCheckIn = provider.getActiveCheckIn(
                            member.id,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCheckedIn
                                    ? Colors.green
                                    : Colors.grey,
                                child: Icon(
                                  isCheckedIn
                                      ? Icons.check_circle
                                      : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                member.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.email),
                                  if (isCheckedIn && activeCheckIn != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Checked in at: ${DateFormat('HH:mm').format(activeCheckIn.checkInTime)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      'Duration: ${_formatDuration(DateTime.now().difference(activeCheckIn.checkInTime))}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  if (isCheckedIn) {
                                    provider.checkOut(member.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${member.name} checked out',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  } else {
                                    provider.checkIn(member.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${member.name} checked in',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  isCheckedIn ? Icons.logout : Icons.login,
                                ),
                                label: Text(
                                  isCheckedIn ? 'Check Out' : 'Check In',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCheckedIn
                                      ? Colors.orange
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                ),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
