import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndDownloadHistoryPdf(
    BuildContext context, {
    required String driverName,
    required String phone,
    required String fleetId,
    required String email,
    required DateTime? unlockedAt,
    required String? unlockPlaceName,
    required double? unlockLat,
    required double? unlockLng,
    required String? unlockedBy,
    required DateTime? lockedAt,
    required String? lockPlaceName,
    required double? lockLat,
    required double? lockLng,
    required String? lockedBy,
  }) async {
    final pdf = pw.Document();
    
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    // Create Map Links
    String getMapLink(double? lat, double? lng) {
      if (lat == null || lng == null) return 'No Location Available';
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }

    final unlockLink = getMapLink(unlockLat, unlockLng);
    final lockLink = getMapLink(lockLat, lockLng);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'Carrier Lock History Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 32),

              // Driver Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Driver Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 12),
                    _buildRow('Name:', driverName),
                    _buildRow('Phone Number:', phone),
                    _buildRow('Email:', email),
                    _buildRow('Fleet ID:', fleetId),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Unlock Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.teal200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Unlock Event', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.SizedBox(height: 12),
                    _buildRow('Date & Time:', unlockedAt != null ? dateFormat.format(unlockedAt) : 'N/A'),
                    _buildRow('Unlocked By:', unlockedBy == 'admin' ? 'Admin' : 'Driver'),
                    _buildRow('Location:', unlockPlaceName ?? (unlockLat != null ? '$unlockLat, $unlockLng' : 'Unknown')),
                    pw.SizedBox(height: 8),
                    _buildLink('Google Maps Link:', unlockLink),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Lock Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Lock Event', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                    pw.SizedBox(height: 12),
                    _buildRow('Date & Time:', lockedAt != null ? dateFormat.format(lockedAt) : 'Carrier still unlocked'),
                    if (lockedAt != null) ...[
                      _buildRow('Locked By:', lockedBy == 'admin' ? 'Admin' : 'Driver'),
                      _buildRow('Location:', lockPlaceName ?? (lockLat != null ? '$lockLat, $lockLng' : 'Unknown')),
                      pw.SizedBox(height: 8),
                      _buildLink('Google Maps Link:', lockLink),
                    ],
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'Generated by CarrierLock Admin System on ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final bytes = await pdf.save();
      final dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final fileName = 'history_${driverName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads folder ($fileName)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLink(String label, String url) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          ),
          pw.Expanded(
            child: pw.UrlLink(
              destination: url,
              child: pw.Text(url, style: const pw.TextStyle(color: PdfColors.blue800, decoration: pw.TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }
}
