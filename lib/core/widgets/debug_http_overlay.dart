import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/http_logger.dart';
import '../services/app_logger.dart';

enum LogTab { http, app }

class DebugHttpOverlay extends StatefulWidget {
  final Widget child;

  const DebugHttpOverlay({super.key, required this.child});

  @override
  State<DebugHttpOverlay> createState() => _DebugHttpOverlayState();
}

class _DebugHttpOverlayState extends State<DebugHttpOverlay> {
  bool _isExpanded = false;
  LogTab _currentTab = LogTab.app;
  final HttpLogger _httpLogger = HttpLogger();
  final AppLogger _appLogger = AppLogger();

  @override
  void initState() {
    super.initState();
    _appLogger.init();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded) ...[
                _buildLogViewer(),
                const SizedBox(height: 10),
              ],
              _buildToggleButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton() {
    final hasHttp = _httpLogger.logs.isNotEmpty;
    final hasApp = _appLogger.totalCount > 0;
    final hasErrors = _appLogger.errorCount > 0;
    
    Color badgeColor = Colors.grey;
    if (hasHttp && hasApp) badgeColor = Colors.purple;
    else if (hasHttp) badgeColor = Colors.orange;
    else if (hasApp) badgeColor = hasErrors ? Colors.red : Colors.blue;

    return GestureDetector(
      onLongPress: () {
        _httpLogger.clear();
        _appLogger.clear();
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('[Logger] All logs cleared'), duration: Duration(seconds: 1)),
          );
        }
      },
      child: FloatingActionButton(
        mini: true,
        backgroundColor: badgeColor,
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
        child: Badge(
          isLabelVisible: hasHttp || hasApp,
          label: Text('${_httpLogger.logs.length + _appLogger.totalCount}'),
          backgroundColor: hasErrors ? Colors.red : null,
          child: Icon(_isExpanded ? Icons.close : Icons.bug_report, size: 20),
        ),
      ),
    );
  }

  Widget _buildLogViewer() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      height: screenHeight * 0.4,  // 40% of screen height
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.grey[900],
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabHeader(),
              Flexible(
                child: _currentTab == LogTab.http ? _buildHttpLogs() : _buildAppLogs(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildTabButton('App', LogTab.app, _appLogger.totalCount, _appLogger.errorCount > 0 ? Colors.red : Colors.blue),
          const SizedBox(width: 8),
          _buildTabButton('HTTP', LogTab.http, _httpLogger.logs.length, Colors.orange),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
            onPressed: () {
              if (_currentTab == LogTab.http) {
                _httpLogger.clear();
              } else {
                _appLogger.clear();
              }
              setState(() {});
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white70, size: 20),
            onPressed: () {
              if (_currentTab == LogTab.app) {
                _appLogger.export();
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs exported to console'), duration: Duration(seconds: 1)),
                  );
                }
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Export',
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, LogTab tab, int count, Color color) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isSelected ? color : Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHttpLogs() {
    final logs = _httpLogger.getAll();
    
    if (logs.isEmpty) {
      return const Center(child: Text('No HTTP requests yet', style: TextStyle(color: Colors.white54)));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: logs.length,
        itemBuilder: (context, index) => _buildHttpLogItem(logs[index]),
      ),
    );
  }

  Widget _buildAppLogs() {
    final logs = _appLogger.allLogs;
    
    if (logs.isEmpty) {
      return const Center(child: Text('No app logs yet', style: TextStyle(color: Colors.white54)));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: logs.length,
        itemBuilder: (context, index) => _buildAppLogItem(logs[index]),
      ),
    );
  }

  Widget _buildHttpLogItem(HttpLogEntry log) {
    final color = log.isSuccess ? Colors.green : (log.isError ? Colors.red : Colors.orange);
    
    return InkWell(
      onTap: () => _showHttpLogDetail(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(log.method, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.url.split('?').first.split('/').last,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${log.statusCode}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 6),
            Text('${log.duration}ms', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogItem(LogEntry log) {
    Color color;
    IconData icon;
    
    switch (log.level) {
      case LogLevel.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case LogLevel.info:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.notes;
    }
    
    return InkWell(
      onTap: () => _showAppLogDetail(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.preview,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(log.formattedTime, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      if (log.tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(log.tag!, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHttpLogDetail(HttpLogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(
                children: [
                  Expanded(child: Text('${log.method} ${log.url}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailSection('Status', '${log.statusCode} (${log.duration}ms)'),
                  _buildDetailSection('URL', log.url),
                  if (log.responseBody != null) _buildDetailSection('Response', log.responseBody!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppLogDetail(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getLevelColor(log.level).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_getLevelIcon(log.level), color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${log.level.label}${log.tag != null ? ' [${log.tag}]' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailSection('Time', log.formattedTime),
                  _buildDetailSection('Message', log.message),
                  if (log.error != null) _buildDetailSection('Error', log.error.toString()),
                  if (log.stackTrace != null) _buildDetailSection('Stack Trace', log.stackTrace.toString()),
                ],
              ),
            ),
          ],
        ),
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

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error: return Icons.error;
      case LogLevel.warning: return Icons.warning;
      case LogLevel.info: return Icons.info;
      default: return Icons.notes;
    }
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
          child: SelectableText(content, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class HttpLoggingClient extends LoggingClient {
  static final HttpLoggingClient _instance = HttpLoggingClient._internal();
  factory HttpLoggingClient() => _instance;
  HttpLoggingClient._internal();
  
  http.Client get client => this;
}

http.Client getHttpClient() => HttpLoggingClient();