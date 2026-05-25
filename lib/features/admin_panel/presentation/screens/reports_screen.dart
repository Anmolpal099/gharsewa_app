import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/admin_api_service.dart';
import '../../data/services/report_export_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _reportType = 'bookings';
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _loading = false;

  final _exportService = ReportExportService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select report type and date range, then export as CSV or PDF.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _reportType,
                    decoration: const InputDecoration(
                      labelText: 'Report type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'users', child: Text('Users')),
                      DropdownMenuItem(
                        value: 'bookings',
                        child: Text('Bookings'),
                      ),
                      DropdownMenuItem(
                        value: 'revenue',
                        child: Text('Revenue'),
                      ),
                      DropdownMenuItem(
                        value: 'services',
                        child: Text('Services'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _reportType = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date range'),
                    subtitle: Text(
                      '${_range.start.toString().split(' ').first} — '
                      '${_range.end.toString().split(' ').first}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _range,
                      );
                      if (picked != null) setState(() => _range = picked);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_loading) const LinearProgressIndicator(),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : () => _export('csv'),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export CSV'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : () => _export('pdf'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(String format) async {
    setState(() => _loading = true);
    try {
      final report = await ref.read(adminApiServiceProvider).generateReport(
            type: _reportType,
            format: format,
            startDate: _range.start,
            endDate: _range.end,
          );

      final headers = _exportService.headersFromReportData(report);
      final rows = _exportService.rowsFromReportData(report);
      final typeLabel = _reportType.isEmpty
          ? 'Report'
          : '${_reportType[0].toUpperCase()}${_reportType.length > 1 ? _reportType.substring(1) : ''} Report';
      final title = typeLabel;
      final subtitle =
          '${_range.start.toString().split(' ').first} to ${_range.end.toString().split(' ').first}';

      if (format == 'csv') {
        await _exportService.exportCsv(
          title: title,
          headers: headers.isEmpty ? ['id'] : headers,
          rows: rows.isEmpty ? [['No data']] : rows,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV copied to clipboard'),
            ),
          );
        }
      } else {
        await _exportService.exportPdf(
          title: title,
          headers: headers.isEmpty ? ['id'] : headers,
          rows: rows.isEmpty ? [['No data']] : rows,
          subtitle: subtitle,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
