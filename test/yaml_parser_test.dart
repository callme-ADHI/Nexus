import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:nexus/core/database/app_database.dart';
import 'package:nexus/core/services/yaml_parser.dart';
import 'package:nexus/core/models/models.dart';

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
  final List<Goal> goalsList = [];
  final List<GoalDependency> dependenciesList = [];

  FakeDatabase() : super.withExecutor(MockExecutor());

  @override
  Future<List<Goal>> getAllGoals() async => goalsList;

  @override
  Future<List<GoalDependency>> getAllDependencies() async => dependenciesList;

  @override
  Future<void> close() async {}
}

void main() {
  group('YamlParser Multi-Document and Strict Deadline Tests', () {
    late FakeDatabase db;
    late YamlParser parser;

    setUp(() {
      db = FakeDatabase();
      parser = YamlParser(db);
    });

    test('should parse concatenated multi-document YAML and extract has_strict_deadline correctly', () async {
      const multiDocYaml = r'''
version: "1.0"

goals:
  - id: transformation
    name: "12-Month Transformation"
    aim: "Become a skilled builder, strong athlete, and connected professional by June 2027"
    timeframe: year
    deadline: "2027-06-07"
    has_strict_deadline: true
    weight: 10
    tasks:
      - name: "Wake — drink water, sit quietly 10 min, no phone"
        schedule: daily
        reminder: "05:00"
        active: true

  - id: projects
    name: "Flagship Projects"
    aim: "Deploy ML and cybersecurity projects publicly for portfolio and internships"
    timeframe: month
    deadline: "2027-03-07"
    weight: 8
    parent: transformation
    tasks:
      - name: "Deep project work"
        schedule: daily
        reminder: "08:30"
        active: true

---
version: "1.0"

goals:
  - id: vshape_body_60days
    name: "Build V-Shape Body in 60 Days"
    aim: "Achieve visible V-taper at 55-57kg with strength, speed, and flexibility"
    timeframe: month
    deadline: "2026-08-05"
    has_strict_deadline: true
    start_date: "2026-06-07"
    weight: 10
    tasks:
      - name: "Review daily program and log overall progress"
        schedule: daily
        reminder: "21:15"
        active: true
''';

      final result = await parser.parse(multiDocYaml);

      expect(result.errors, isEmpty);
      expect(result.validGoals, hasLength(3));

      // Asserting values for transformation goal
      final transformation = result.validGoals.firstWhere((g) => g.id == 'transformation');
      expect(transformation.name, equals('12-Month Transformation'));
      expect(transformation.hasStrictDeadline, isTrue);

      // Asserting values for projects goal
      final projects = result.validGoals.firstWhere((g) => g.id == 'projects');
      expect(projects.name, equals('Flagship Projects'));
      expect(projects.hasStrictDeadline, isFalse); // Default fallback

      // Asserting values for vshape_body_60days goal
      final vshape = result.validGoals.firstWhere((g) => g.id == 'vshape_body_60days');
      expect(vshape.name, equals('Build V-Shape Body in 60 Days'));
      expect(vshape.hasStrictDeadline, isTrue);
    });
  });
}
