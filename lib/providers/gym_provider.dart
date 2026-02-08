import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../models/membership_plan.dart';
import '../models/check_in.dart';
import '../repositories/gym_repository.dart';

class GymProvider with ChangeNotifier {
  final GymRepository _repo = GymRepository();

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

  GymProvider() {
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
  Future<void> addMember(Member member) async {
    await _repo.upsertMember(member);
    _members.insert(0, member);
    notifyListeners();
  }

  Future<void> updateMember(Member member) async {
    await _repo.upsertMember(member);
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      notifyListeners();
    }
  }

  Future<void> deleteMember(String memberId) async {
    await _repo.deleteMember(memberId);
    _members.removeWhere((m) => m.id == memberId);
    _checkIns.removeWhere((ci) => ci.memberId == memberId);
    notifyListeners();
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
  Future<void> addMembershipPlan(MembershipPlan plan) async {
    await _repo.upsertPlan(plan);
    _membershipPlans.add(plan);
    notifyListeners();
  }

  Future<void> updateMembershipPlan(MembershipPlan plan) async {
    await _repo.upsertPlan(plan);
    final index = _membershipPlans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _membershipPlans[index] = plan;
      notifyListeners();
    }
  }

  Future<void> deleteMembershipPlan(String planId) async {
    _membershipPlans.removeWhere((p) => p.id == planId);
    // Note: DB cleanup handled if required
    notifyListeners();
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
}
