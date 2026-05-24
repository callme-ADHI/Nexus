import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/productivity_service.dart';
import '../productivity/productivity_providers.dart';

class LogImportPage extends ConsumerStatefulWidget {
  const LogImportPage({super.key});

  @override
  ConsumerState<LogImportPage> createState() => _LogImportPageState();
}

class _LogImportPageState extends ConsumerState<LogImportPage> {
  final _textCtrl = TextEditingController();
  bool _isLoading = false;
  YamlImportResult? _parsedResult;
  String? _parseError;
  bool _overwrite = true; // Overwrite logs by default to "restore all the log"

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateYaml() async {
    setState(() {
      _isLoading = true;
      _parsedResult = null;
      _parseError = null;
    });

    try {
      final parser = ref.read(yamlParserProvider);
      final result = await parser.parse(_textCtrl.text);
      setState(() {
        _parsedResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _parseError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _commitLogs() async {
    final result = _parsedResult;
    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      
      await db.transaction(() async {
        if (_overwrite) {
          await db.clearAllLogs();
        }

        // Insert Activity Logs
        for (final a in result.activityLogs) {
          await db.insertActivity(ActivityLogsCompanion.insert(
            date: a.date,
            category: a.category,
            name: a.name,
            startTime: a.startTime,
            endTime: a.endTime,
            notes: Value(a.notes),
            isAuto: Value(a.isAuto ? 1 : 0),
            createdAt: a.createdAt,
          ));
        }

        // Insert Sleep Logs
        for (final s in result.sleepLogs) {
          await db.insertSleep(SleepLogsCompanion.insert(
            date: s.date,
            sleepTime: s.sleepTime,
            wakeTime: s.wakeTime,
            qualityNote: Value(s.qualityNote),
            createdAt: s.createdAt,
          ));
        }

        // Calculate and cache productivity scores for all unique imported dates
        final uniqueDates = <int>{};
        for (final a in result.activityLogs) {
          uniqueDates.add(a.date);
        }
        for (final s in result.sleepLogs) {
          uniqueDates.add(s.date);
        }

        for (final dMs in uniqueDates) {
          final dayActivities = result.activityLogs
              .where((a) => a.date == dMs)
              .map((a) => ActivityLog(
                    id: 0,
                    date: a.date,
                    category: a.category,
                    name: a.name,
                    startTime: a.startTime,
                    endTime: a.endTime,
                    notes: a.notes,
                    isAuto: a.isAuto ? 1 : 0,
                    createdAt: a.createdAt,
                  ))
              .toList();

          final daySleepYaml = result.sleepLogs
              .where((s) => s.date == dMs)
              .firstOrNull;
          final daySleep = daySleepYaml == null
              ? null
              : SleepLog(
                  id: 0,
                  date: daySleepYaml.date,
                  sleepTime: daySleepYaml.sleepTime,
                  wakeTime: daySleepYaml.wakeTime,
                  qualityNote: daySleepYaml.qualityNote,
                  createdAt: daySleepYaml.createdAt,
                );

          final score = ProductivityService.calculate(
            activities: dayActivities,
            sleep: daySleep,
            completedTasksCount: 0,
          );

          await ProductivityService.cacheScore(db, dMs, score);
        }
      });

      // Force recalculate productivity caches
      ref.invalidate(activitiesProvider);
      ref.invalidate(sleepProvider);
      ref.invalidate(productivityScoreProvider);
      ref.invalidate(cachedScoresProvider);
      ref.invalidate(rangeActivitiesProvider);
      ref.invalidate(rangeSleepProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${result.activityLogs.length} activity logs and ${result.sleepLogs.length} sleep logs!',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATA RESTORATION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            color: const Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import YAML Logs',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Processing YAML…', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_parsedResult == null && _parseError == null) ...[
                            // Hint
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Paste your YAML containing activity_logs and sleep_logs below to restore past tracker entries.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Text area
                            Container(
                              height: 350,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: TextField(
                                controller: _textCtrl,
                                maxLines: null,
                                expands: true,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'version: "1.1"\nactivity_logs:\n  - date: 1715817600000\n    category: "deep_work"\n    name: "Coding"\n    ...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.white24,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _validateYaml,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'VALIDATE LOGS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Result view
                            if (_parseError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A0505),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _parseError!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFE74C3C),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_parsedResult != null) ...[
                              Text(
                                'VALIDATION SUMMARY',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              _LogSummaryTile(
                                title: 'Activity Logs Found',
                                count: _parsedResult!.activityLogs.length,
                                icon: Icons.insights_rounded,
                              ),
                              const SizedBox(height: 8),
                              _LogSummaryTile(
                                title: 'Sleep Logs Found',
                                count: _parsedResult!.sleepLogs.length,
                                icon: Icons.bedtime_rounded,
                              ),
                              const SizedBox(height: 24),

                              if (_parsedResult!.errors.isNotEmpty) ...[
                                Text(
                                  'WARNINGS / ERRORS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE74C3C),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._parsedResult!.errors.map((err) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text('• $err', style: GoogleFonts.inter(color: const Color(0xFFE74C3C), fontSize: 12)),
                                )),
                                const SizedBox(height: 24),
                              ],

                              Text(
                                'IMPORT PREFERENCE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Overwrite toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _overwrite = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _overwrite ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
                                          border: Border.all(color: _overwrite ? Colors.white : Colors.white10),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'RESTORE (OVERWRITE)',
                                          style: GoogleFonts.inter(
                                            color: _overwrite ? Colors.white : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _overwrite = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_overwrite ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
                                          border: Border.all(color: !_overwrite ? Colors.white : Colors.white10),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'APPEND LOGS',
                                          style: GoogleFonts.inter(
                                            color: !_overwrite ? Colors.white : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 32),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _parsedResult = null;
                                        _parseError = null;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'EDIT YAML',
                                      style: GoogleFonts.inter(fontSize: 12, letterSpacing: 1.0, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (_parsedResult != null && 
                                               (_parsedResult!.activityLogs.isNotEmpty || _parsedResult!.sleepLogs.isNotEmpty)) 
                                        ? _commitLogs 
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      'IMPORT',
                                      style: GoogleFonts.inter(fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogSummaryTile extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _LogSummaryTile({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
