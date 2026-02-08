import 'package:flutter/foundation.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/entities/check_in.dart';
import '../../domain/repositories/gym_repository.dart';
import '../../data/repositories/gym_repository_impl.dart';
import '../../core/utils/file_export.dart';

class GymViewModel with ChangeNotifier {
  final GymRepository _repo = GymRepositoryImpl();

  // Pagination settings
  final int _pageSize = 50;
  bool _isLoadingMembers = false;
  bool _hasMoreMembers = true;

  List<Member> _members = [];
  List<MembershipPlan> _membershipPlans = [];
  List<CheckIn> _checkIns = [];

  List<Member> get members => _members;
  List<MembershipPlan> get membershipPlans => _membershipPlans;
  List<CheckIn> get checkIns => _checkIns;

  List<CheckIn> get activeCheckIns =>
      _checkIns.where((ci) => ci.isCheckedIn).toList();

  GymViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load plans from DB; if empty, add defaults
    _membershipPlans = await _repo.getAllPlans();
    if (_membershipPlans.isEmpty) {
      _membershipPlans = [
        MembershipPlan(
          id: '1',
          name: '1 Month',
          price: 600.0,
          durationDays: 30,
          description: '1 month gym membership',
        ),
        MembershipPlan(
          id: '2',
          name: '3 Months',
          price: 1500.0,
          durationDays: 90,
          description: '3 months gym membership',
        ),
      ];
      for (final p in _membershipPlans) {
        await _repo.upsertPlan(p);
      }
    }

    // Load initial page of members
    await _loadNextMembersPage();

    // Load active check-ins
    _checkIns = await _repo.getActiveCheckIns();

    notifyListeners();
  }

  Future<void> _loadNextMembersPage() async {
    if (_isLoadingMembers || !_hasMoreMembers) return;
    _isLoadingMembers = true;
    final offset = _members.length;
    final fetched = await _repo.fetchMembersPaginated(offset, _pageSize);
    _members.addAll(fetched);
    if (fetched.length < _pageSize) _hasMoreMembers = false;
    _isLoadingMembers = false;
    notifyListeners();
  }

  Future<void> loadMoreMembers() async => await _loadNextMembersPage();

  // Member management
  Future<String?> addMember(Member member) async {
    try {
      // Check for duplicate email
      final existingMember = _members.firstWhere(
        (m) => m.email.toLowerCase() == member.email.toLowerCase(),
        orElse: () => Member(
          id: '',
          name: '',
          email: '',
          phone: '',
          membershipPlanId: '',
          joinDate: DateTime.now(),
        ),
      );
      
      if (existingMember.id.isNotEmpty && existingMember.id != member.id) {
        return 'A member with this email already exists';
      }

      await _repo.upsertMember(member);
      _members.insert(0, member);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Failed to add member: ${e.toString()}';
    }
  }

  Future<String?> updateMember(Member member) async {
    try {
      // Check for duplicate email (excluding current member)
      final existingMember = _members.firstWhere(
        (m) => m.email.toLowerCase() == member.email.toLowerCase() && m.id != member.id,
        orElse: () => Member(
          id: '',
          name: '',
          email: '',
          phone: '',
          membershipPlanId: '',
          joinDate: DateTime.now(),
        ),
      );
      
      if (existingMember.id.isNotEmpty) {
        return 'A member with this email already exists';
      }

      await _repo.upsertMember(member);
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _members[index] = member;
        notifyListeners();
      }
      return null; // Success
    } catch (e) {
      return 'Failed to update member: ${e.toString()}';
    }
  }

  Future<String?> deleteMember(String memberId) async {
    try {
      await _repo.deleteMember(memberId);
      _members.removeWhere((m) => m.id == memberId);
      _checkIns.removeWhere((ci) => ci.memberId == memberId);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Failed to delete member: ${e.toString()}';
    }
  }

  Future<Member?> getMemberById(String id) async {
    // First try in-memory cache
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return await _repo.getMemberById(id);
    }
  }

  // Synchronous lookup against in-memory page cache (used by UI for fast lookups)
  Member? getMemberByIdSync(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Membership plan management
  Future<String?> addMembershipPlan(MembershipPlan plan) async {
    try {
      await _repo.upsertPlan(plan);
      _membershipPlans.add(plan);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Failed to add plan: ${e.toString()}';
    }
  }

  Future<String?> updateMembershipPlan(MembershipPlan plan) async {
    try {
      await _repo.upsertPlan(plan);
      final index = _membershipPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _membershipPlans[index] = plan;
        notifyListeners();
      }
      return null; // Success
    } catch (e) {
      return 'Failed to update plan: ${e.toString()}';
    }
  }

  Future<String?> deleteMembershipPlan(String planId) async {
    try {
      // Check if any members are using this plan
      final membersUsingPlan = _members.where((m) => m.membershipPlanId == planId).length;
      if (membersUsingPlan > 0) {
        return 'Cannot delete plan: $membersUsingPlan member(s) are using this plan';
      }

      await _repo.deletePlan(planId);
      _membershipPlans.removeWhere((p) => p.id == planId);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Failed to delete plan: ${e.toString()}';
    }
  }

  MembershipPlan? getMembershipPlanById(String id) {
    try {
      return _membershipPlans.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check-in management
  Future<void> checkIn(String memberId) async {
    final checkIn = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      checkInTime: DateTime.now(),
    );
    await _repo.insertCheckIn(checkIn);
    _checkIns.add(checkIn);
    notifyListeners();
  }

  Future<void> checkOut(String memberId) async {
    final ci = _checkIns.firstWhere(
      (ci) => ci.memberId == memberId && ci.isCheckedIn,
    );
    final updated = ci.copyWith(checkOutTime: DateTime.now());
    await _repo.updateCheckIn(updated);
    final index = _checkIns.indexOf(ci);
    _checkIns[index] = updated;
    notifyListeners();
  }

  bool isMemberCheckedIn(String memberId) {
    return _checkIns.any((ci) => ci.memberId == memberId && ci.isCheckedIn);
  }

  CheckIn? getActiveCheckIn(String memberId) {
    try {
      return _checkIns.firstWhere(
        (ci) => ci.memberId == memberId && ci.isCheckedIn,
      );
    } catch (e) {
      return null;
    }
  }

  // Statistics
  int get totalMembers => _members.length;
  int get activeMembers => _members.where((m) => m.isActive).length;
  int get checkedInCount => activeCheckIns.length;

  bool get hasMoreMembers => _hasMoreMembers;
  bool get isLoadingMembers => _isLoadingMembers;

  int get expiredOrUnpaidMembersCount {
    final now = DateTime.now();
    return _members.where((member) {
      final isExpired =
          member.expiryDate != null && member.expiryDate!.isBefore(now);
      final isInactive = !member.isActive;
      return isExpired || isInactive;
    }).length;
  }

  int get expiringSoonMembersCount {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return _members.where((member) {
      if (member.expiryDate == null || !member.isActive) return false;
      final expiry = member.expiryDate!;
      return expiry.isAfter(now) && expiry.isBefore(sevenDaysFromNow);
    }).length;
  }

  List<Member> getExpiredOrUnpaidMembers() {
    final now = DateTime.now();
    return _members.where((member) {
      final isExpired =
          member.expiryDate != null && member.expiryDate!.isBefore(now);
      final isInactive = !member.isActive;
      return isExpired || isInactive;
    }).toList();
  }

  List<Member> getExpiringSoonMembers() {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return _members.where((member) {
      if (member.expiryDate == null || !member.isActive) return false;
      final expiry = member.expiryDate!;
      return expiry.isAfter(now) && expiry.isBefore(sevenDaysFromNow);
    }).toList();
  }

  int getTodayCheckIns() {
    final today = DateTime.now();
    return _checkIns.where((ci) {
      return ci.checkInTime.year == today.year &&
          ci.checkInTime.month == today.month &&
          ci.checkInTime.day == today.day;
    }).length;
  }

  /// Persist any in-memory caches to disk (bulk upserts). Call on app pause/exit.
  Future<void> flushToDisk() async {
    try {
      await _repo.bulkUpsertPlans(_membershipPlans);
      await _repo.bulkUpsertMembers(_members);
      await _repo.bulkUpsertCheckIns(_checkIns);
    } catch (e) {
      if (kDebugMode) print('Error flushing to disk: $e');
    }
  }

  // Export functionality
  Future<String?> exportMembersToCSV() async {
    try {
      return await FileExport.exportMembersToCSV(_members, _membershipPlans);
    } catch (e) {
      return null;
    }
  }

  Future<String?> exportPlansToCSV() async {
    try {
      return await FileExport.exportPlansToCSV(_membershipPlans);
    } catch (e) {
      return null;
    }
  }

  Future<String?> exportCheckInsToCSV() async {
    try {
      return await FileExport.exportCheckInsToCSV(_checkIns, _members);
    } catch (e) {
      return null;
    }
  }
}
