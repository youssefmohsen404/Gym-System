import '../services/database_service.dart';
import '../models/member.dart';
import '../models/membership_plan.dart';
import '../models/check_in.dart';

class GymRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<MembershipPlan>> getAllPlans() async => await _db.getAllPlans();
  Future<void> upsertPlan(MembershipPlan p) async =>
      await _db.insertOrUpdatePlan(p);

  Future<void> upsertMember(Member m) async =>
      await _db.insertOrUpdateMember(m);
  Future<void> deleteMember(String id) async => await _db.deleteMember(id);
  Future<Member?> getMemberById(String id) async => await _db.getMemberById(id);
  Future<List<Member>> fetchMembersPaginated(int offset, int limit) async =>
      await _db.fetchMembersPaginated(offset: offset, limit: limit);
  Future<int> countMembers() async => await _db.countMembers();

  Future<void> insertCheckIn(CheckIn ci) async => await _db.insertCheckIn(ci);
  Future<List<CheckIn>> getActiveCheckIns() async =>
      await _db.getActiveCheckIns();
  Future<void> updateCheckIn(CheckIn ci) async => await _db.updateCheckIn(ci);

  // Bulk operations
  Future<void> bulkUpsertMembers(List<Member> members) async =>
      await _db.bulkUpsertMembers(members);
  Future<void> bulkUpsertPlans(List<MembershipPlan> plans) async =>
      await _db.bulkUpsertPlans(plans);
  Future<void> bulkUpsertCheckIns(List<CheckIn> checkIns) async =>
      await _db.bulkUpsertCheckIns(checkIns);
}
