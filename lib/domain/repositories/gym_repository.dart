import '../entities/member.dart';
import '../entities/membership_plan.dart';
import '../entities/check_in.dart';

/// Repository interface for gym data operations
/// This is part of the domain layer and defines the contract
/// for data access operations
abstract class GymRepository {
  // Membership Plans
  Future<List<MembershipPlan>> getAllPlans();
  Future<void> upsertPlan(MembershipPlan plan);
  Future<void> deletePlan(String planId);
  
  // Members
  Future<void> upsertMember(Member member);
  Future<void> deleteMember(String id);
  Future<Member?> getMemberById(String id);
  Future<List<Member>> fetchMembersPaginated(int offset, int limit);
  Future<int> countMembers();
  
  // Check-ins
  Future<void> insertCheckIn(CheckIn checkIn);
  Future<List<CheckIn>> getActiveCheckIns();
  Future<void> updateCheckIn(CheckIn checkIn);
  
  // Bulk operations
  Future<void> bulkUpsertMembers(List<Member> members);
  Future<void> bulkUpsertPlans(List<MembershipPlan> plans);
  Future<void> bulkUpsertCheckIns(List<CheckIn> checkIns);
}

