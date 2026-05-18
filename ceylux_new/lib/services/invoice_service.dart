import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class InvoiceService {
  static Future<void> shareInvoice(AppOrder order) async {
    final pdf = pw.Document();

    final goldColor = PdfColor.fromHex('#C9A84C');
    final darkColor = PdfColor.fromHex('#1A1A2E');
    final mutedColor = PdfColor.fromHex('#888888');
    final bgColor = PdfColor.fromHex('#F5F0E8');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: darkColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CEYLUX',
                          style: pw.TextStyle(
                            color: goldColor, fontSize: 28,
                            fontWeight: pw.FontWeight.bold, letterSpacing: 4,
                          ),
                        ),
                        pw.Text('FASHION',
                          style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 10, letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(order.id,
                          style: pw.TextStyle(color: goldColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Customer & Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO',
                        style: pw.TextStyle(
                          fontSize: 9, color: mutedColor,
                          letterSpacing: 1.5, fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(order.customerName,
                        style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DATE',
                        style: pw.TextStyle(
                          fontSize: 9, color: mutedColor,
                          letterSpacing: 1.5, fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(order.date,
                        style: pw.TextStyle(fontSize: 13, color: darkColor),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: goldColor,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(order.status,
                          style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: goldColor, thickness: 0.5),
              pw.SizedBox(height: 12),

              // Table header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: bgColor, borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text('ITEM',
                      style: pw.TextStyle(fontSize: 9, color: mutedColor,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 1))),
                    pw.Expanded(flex: 1, child: pw.Text('SIZE',
                      style: pw.TextStyle(fontSize: 9, color: mutedColor,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 1, child: pw.Text('QTY',
                      style: pw.TextStyle(fontSize: 9, color: mutedColor,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text('PRICE',
                      style: pw.TextStyle(fontSize: 9, color: mutedColor,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text('SUBTOTAL',
                      style: pw.TextStyle(fontSize: 9, color: mutedColor,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Items
              ...order.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text(item.name,
                      style: pw.TextStyle(fontSize: 12, color: darkColor,
                        fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text(item.size,
                      style: pw.TextStyle(fontSize: 11, color: darkColor),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 1, child: pw.Text('${item.qty}',
                      style: pw.TextStyle(fontSize: 11, color: darkColor),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text(
                      'Rs. ${NumberFormat('#,###').format(item.price)}',
                      style: pw.TextStyle(fontSize: 11, color: darkColor),
                      textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text(
                      'Rs. ${NumberFormat('#,###').format(item.subtotal)}',
                      style: pw.TextStyle(fontSize: 11, color: darkColor,
                        fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right)),
                  ],
                ),
              )),

              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColor.fromHex('#DDDDDD'), thickness: 0.5),
              pw.SizedBox(height: 12),

              // Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: darkColor, borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('TOTAL  ',
                        style: pw.TextStyle(
                          color: PdfColors.white, fontSize: 13,
                          letterSpacing: 1, fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Rs. ${NumberFormat('#,###').format(order.total)}',
                        style: pw.TextStyle(
                          color: goldColor, fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColor.fromHex('#DDDDDD'), thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with CEYLUX Fashion Boutique',
                  style: pw.TextStyle(color: mutedColor, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save to temp file
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/CEYLUX_Invoice_${order.id}.pdf');
    await file.writeAsBytes(bytes);

    // Share via native share sheet
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'CEYLUX Invoice - ${order.id}',
      text: 'Invoice for ${order.customerName} — Rs. ${NumberFormat('#,###').format(order.total)}',
    );
  }
}