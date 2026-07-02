import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/http_logger.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HttpLogger _httpLogger = HttpLogger();
  final AppLogger _appLogger = AppLogger();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _exportAllLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== LIQUID eKYC DEBUG LOG ===');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('Device: ${Theme.of(context).platform.toString()}');
    buffer.writeln('');

    buffer.writeln('--- APP LOGS (${_appLogger.allLogs.length}) ---');
    for (final log in _appLogger.allLogs) {
      buffer.writeln('[${log.formattedTime}] ${log.level.label}${log.tag != null ? ' [${log.tag}]' : ''}');
      buffer.writeln('  ${log.message}');
      if (log.error != null) {
        buffer.writeln('  ERROR: $log.error');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  STACK: $log.stackTrace');
      }
    }

    buffer.writeln('');
    buffer.writeln('--- HTTP LOGS (${_httpLogger.logs.length}) ---');
    for (final log in _httpLogger.getAll()) {
      buffer.writeln('[${log.startTime}] ${log.method} ${log.url}');
      buffer.writeln('  Status: ${log.statusCode} (${log.duration}ms)');
      if (log.responseBody != null) {
        buffer.writeln('  Response: ${log.responseBody}');
      }
    }

    return buffer.toString();
  }

  void _copyLogs() {
    final logs = _exportAllLogs();
    Clipboard.setData(ClipboardData(text: logs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  void _shareLogs() {
    final logs = _exportAllLogs();
    Share.share(logs, subject: 'Liquid eKYC Debug Logs');
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Clear all logs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _httpLogger.clear();
              _appLogger.clear();
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All logs cleared'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy to clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
            tooltip: 'Share logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notes, size: 18),
                  const SizedBox(width: 6),
                  Text('App (${_appLogger.totalCount})${_appLogger.errorCount > 0 ? ' ⚠️' : ''}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.http, size: 18),
                  const SizedBox(width: 6),
                  Text('HTTP (${_httpLogger.logs.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[850],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppLogsTab(),
          _buildHttpLogsTab(),
        ],
      ),
    );
  }

  Widget _buildAppLogsTab() {
    final logs = _appLogger.allLogs;

    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No app logs yet', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildAppLogCard(log);
      },
    );
  }

  Widget _buildAppLogCard(LogEntry log) {
    Color color;
    IconData icon;

    switch (log.level) {
      case LogLevel.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case LogLevel.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.notes;
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showLogDetail(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.level.label,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.formattedTime,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.message,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (log.tag != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.tag!,
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHttpLogsTab() {
    final logs = _httpLogger.getAll();

    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.http, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No HTTP requests yet', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildHttpLogCard(log);
      },
    );
  }

  Widget _buildHttpLogCard(HttpLogEntry log) {
    final color = log.isSuccess ? Colors.green : (log.isError ? Colors.red : Colors.orange);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showHttpDetail(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.method,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${log.statusCode}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${log.duration}ms',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.url,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (log.responseBody != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.responseBody!.length > 100
                            ? '${log.responseBody!.substring(0, 100)}...'
                            : log.responseBody!,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(LogEntry log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${log.level.label} Details'),
            backgroundColor: _getLevelColor(log.level),
          ),
          backgroundColor: Colors.grey[900],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Time', log.formattedTime),
                _buildDetailRow('Level', log.level.label),
                if (log.tag != null) _buildDetailRow('Tag', log.tag!),
                _buildDetailRow('Message', log.message),
                if (log.error != null) _buildDetailRow('Error', log.error.toString()),
                if (log.stackTrace != null) _buildDetailRow('Stack Trace', log.stackTrace.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHttpDetail(HttpLogEntry log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${log.method} Request'),
            backgroundColor: Colors.blueGrey,
          ),
          backgroundColor: Colors.grey[900],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('URL', log.url),
                _buildDetailRow('Status', '${log.statusCode}'),
                _buildDetailRow('Duration', '${log.duration}ms'),
                _buildDetailRow('Time', log.startTime.toString()),
                if (log.responseBody != null) _buildDetailRow('Response', log.responseBody!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error: return Colors.red;
      case LogLevel.warning: return Colors.orange;
      case LogLevel.info: return Colors.blue;
      default: return Colors.grey;
    }
  }
}