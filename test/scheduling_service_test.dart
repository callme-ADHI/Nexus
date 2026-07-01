import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/database/app_database.dart';
import 'package:nexus/core/services/scheduling_service.dart';

class MockExecutor extends QueryExecutor {
  @override
  TransactionExecutor beginTransaction() => throw UnimplementedError();
  @override
  QueryExecutor beginExclusive() => throw UnimplementedError();
  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;
  @override
  Future<void> runBatched(BatchedStatements statements) async {}
  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}
  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;
  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;
  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;
  @override
  Future<List<Map<String, Object?>>> runSelect(String statement, List<Object?> args) async => [];
  @override
  SqlDialect get dialect => SqlDialect.sqlite;
}

class FakeDatabase extends AppDatabase {
  FakeDatabase() : super.withExecutor(MockExecutor());
  @override
  Future<void> close() async {}
}

void main() {
  group('SchedulingService Recurrence Algorithm Tests', () {
    late FakeDatabase db;
    late SchedulingService scheduler;

    setUp(() {
      db = FakeDatabase();
      scheduler = SchedulingService(db);
    });

    test('should generate task timestamps only on Mon, Wed, Fri for weekly multi-day schedule', () {
      final now = DateTime.now();
      // Monday of this week
      final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
      final mondayMidnight = DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
      final sundayMidnight = mondayMidnight.add(const Duration(days: 6));

      final task = Task(
        id: 'mwf_task',
        goalId: 'some_goal',
        name: 'MWF Task',
        schedule: 'weekly',
        scheduleOn: 'monday,wednesday,friday',
        reminderTime: '09:00',
        isActive: 1,
        createdAt: mondayMidnight.millisecondsSinceEpoch,
        isTaskOfTheDay: false,
      );

      final dates = scheduler.scheduledDates(task, mondayMidnight, sundayMidnight);

      expect(dates, hasLength(3));
      
      final weekdays = dates.map((d) => DateTime.fromMillisecondsSinceEpoch(d).weekday).toList();
      expect(weekdays, contains(DateTime.monday));
      expect(weekdays, contains(DateTime.wednesday));
      expect(weekdays, contains(DateTime.friday));
      expect(weekdays, isNot(contains(DateTime.tuesday)));
      expect(weekdays, isNot(contains(DateTime.thursday)));
      expect(weekdays, isNot(contains(DateTime.saturday)));
      expect(weekdays, isNot(contains(DateTime.sunday)));
    });

    test('should generate task timestamps with custom weekend breaks for daily schedule', () {
      final now = DateTime.now();
      // Monday of this week
      final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
      final mondayMidnight = DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
      final sundayMidnight = mondayMidnight.add(const Duration(days: 6));

      // Daily task that breaks on Sat and Sun (i.e. only runs Monday, Tuesday, Wednesday, Thursday, Friday)
      final task = Task(
        id: 'daily_with_breaks',
        goalId: 'some_goal',
        name: 'Weekday Task',
        schedule: 'daily',
        scheduleOn: 'monday,tuesday,wednesday,thursday,friday',
        reminderTime: '08:00',
        isActive: 1,
        createdAt: mondayMidnight.millisecondsSinceEpoch,
        isTaskOfTheDay: false,
      );

      final dates = scheduler.scheduledDates(task, mondayMidnight, sundayMidnight);

      expect(dates, hasLength(5));
      
      final weekdays = dates.map((d) => DateTime.fromMillisecondsSinceEpoch(d).weekday).toList();
      expect(weekdays, contains(DateTime.monday));
      expect(weekdays, contains(DateTime.tuesday));
      expect(weekdays, contains(DateTime.wednesday));
      expect(weekdays, contains(DateTime.thursday));
      expect(weekdays, contains(DateTime.friday));
      expect(weekdays, isNot(contains(DateTime.saturday)));
      expect(weekdays, isNot(contains(DateTime.sunday)));
    });
  });
}
