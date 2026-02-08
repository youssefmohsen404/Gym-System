import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/entities/check_in.dart';

/// Utility class for exporting data to CSV format
class FileExport {
  /// Exports members list to CSV file
  static Future<String?> exportMembersToCSV(
    List<Member> members,
    List<MembershipPlan> plans,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/members_export_$timestamp.csv');

      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('ID,Name,Email,Phone,Plan,Join Date,Expiry Date,Status,Active');
      
      // CSV Data
      for (final member in members) {
        final plan = plans.firstWhere(
          (p) => p.id == member.membershipPlanId,
          orElse: () => MembershipPlan(
            id: '',
            name: 'Unknown',
            price: 0,
            durationDays: 0,
          ),
        );
        
        final joinDate = DateFormat('yyyy-MM-dd').format(member.joinDate);
        final expiryDate = member.expiryDate != null
            ? DateFormat('yyyy-MM-dd').format(member.expiryDate!)
            : '';
        final status = member.expiryDate != null
            ? (member.expiryDate!.isBefore(DateTime.now())
                ? 'Expired'
                : 'Active')
            : 'No Expiry';
        
        buffer.writeln(
          '"${member.id}",'
          '"${_escapeCSV(member.name)}",'
          '"${_escapeCSV(member.email)}",'
          '"${_escapeCSV(member.phone)}",'
          '"${_escapeCSV(plan.name)}",'
          '"$joinDate",'
          '"$expiryDate",'
          '"$status",'
          '"${member.isActive ? 'Yes' : 'No'}"',
        );
      }

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Exports membership plans to CSV file
  static Future<String?> exportPlansToCSV(List<MembershipPlan> plans) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/plans_export_$timestamp.csv');

      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('ID,Name,Price,Duration (Days),Description');
      
      // CSV Data
      for (final plan in plans) {
        buffer.writeln(
          '"${plan.id}",'
          '"${_escapeCSV(plan.name)}",'
          '${plan.price},'
          '${plan.durationDays},'
          '"${_escapeCSV(plan.description)}"',
        );
      }

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Exports check-ins to CSV file
  static Future<String?> exportCheckInsToCSV(
    List<CheckIn> checkIns,
    List<Member> members,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/checkins_export_$timestamp.csv');

      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('ID,Member Name,Member Email,Check In Time,Check Out Time,Duration (Hours)');
      
      // CSV Data
      for (final checkIn in checkIns) {
        final member = members.firstWhere(
          (m) => m.id == checkIn.memberId,
          orElse: () => Member(
            id: '',
            name: 'Unknown',
            email: '',
            phone: '',
            membershipPlanId: '',
            joinDate: DateTime.now(),
          ),
        );
        
        final checkInTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(checkIn.checkInTime);
        final checkOutTime = checkIn.checkOutTime != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(checkIn.checkOutTime!)
            : 'Still Checked In';
        
        final duration = checkIn.duration != null
            ? (checkIn.duration!.inHours + checkIn.duration!.inMinutes / 60).toStringAsFixed(2)
            : '';
        
        buffer.writeln(
          '"${checkIn.id}",'
          '"${_escapeCSV(member.name)}",'
          '"${_escapeCSV(member.email)}",'
          '"$checkInTime",'
          '"$checkOutTime",'
          '"$duration"',
        );
      }

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Escapes CSV special characters
  static String _escapeCSV(String value) {
    return value.replaceAll('"', '""');
  }
}

