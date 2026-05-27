import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/order.dart';

class InvoiceService {
  static const String defaultTemplate = r'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CEYLUX Invoice</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f0f4f8 0%, #e8f1f7 100%);
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            border-radius: 12px;
            overflow: hidden;
        }
        
        /* Header Section with Logo */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            background: linear-gradient(135deg, #0C4A6E 0%, #0F5D7D 100%);
            color: white;
            padding: 40px;
            margin-bottom: 0;
            position: relative;
            overflow: hidden;
        }
        
        .header::after {
            content: '';
            position: absolute;
            bottom: -40px;
            right: -80px;
            width: 400px;
            height: 300px;
            background: rgba(134, 189, 218, 0.3);
            border-radius: 50%;
            z-index: 0;
        }
        
        .header > * {
            position: relative;
            z-index: 1;
        }
        
        .header-left {
            display: flex;
            gap: 20px;
            align-items: flex-start;
        }
        
        .logo-placeholder {
            width: 80px;
            height: 80px;
            background: rgba(255, 255, 255, 0.15);
            border: 2px solid rgba(255, 255, 255, 0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 12px;
            color: rgba(255, 255, 255, 0.8);
            font-size: 12px;
            text-align: center;
            flex-shrink: 0;
            backdrop-filter: blur(10px);
        }
        
        .header-text h1 {
            font-size: 32px;
            color: #ffffff;
            font-weight: bold;
            margin-bottom: 5px;
            letter-spacing: 1px;
        }
        
        .header-text p {
            color: #86BDDA;
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .header-contact {
            color: rgba(255, 255, 255, 0.85);
            font-size: 11px;
            line-height: 1.6;
        }
        
        .header-right {
            text-align: right;
        }
        
        .header-right .company-name {
            font-size: 18px;
            font-weight: bold;
            color: #ffffff;
            margin-bottom: 8px;
        }
        
        .header-right .invoice-number {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-bottom: 6px;
            font-size: 12px;
        }
        
        .header-right .invoice-number .label {
            color: rgba(255, 255, 255, 0.7);
            font-weight: 600;
        }
        
        .header-right .invoice-number .value {
            color: #ffffff;
            font-weight: bold;
            min-width: 80px;
        }
        
        .header-right .date {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            font-size: 12px;
            color: rgba(255, 255, 255, 0.85);
        }
        
        /* Bill To Section */
        .bill-to {
            display: flex;
            gap: 40px;
            margin-bottom: 30px;
            padding: 30px 40px;
            background: #f8fafb;
            border-bottom: 1px solid #e8eef4;
        }
        
        .bill-to-section {
            flex: 1;
        }
        
        .bill-to-section h3 {
            font-size: 11px;
            color: #0C4A6E;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }
        
        .bill-to-section .customer-name {
            font-size: 14px;
            font-weight: bold;
            color: #1A1A2E;
            margin-bottom: 6px;
        }
        
        .bill-to-section .address {
            font-size: 12px;
            color: #555;
            line-height: 1.6;
            margin-bottom: 4px;
        }
        
        .bill-to-section .phone {
            font-size: 11px;
            color: #555;
        }
        
        /* Items Table */
        .items-table {
            width: 100%;
            margin: 0;
            border-collapse: collapse;
            background: white;
        }
        
        .items-table thead {
            background: linear-gradient(135deg, #0C4A6E 0%, #0F5D7D 100%);
            color: white;
        }
        
        .items-table th {
            padding: 16px 15px;
            text-align: left;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        
        .items-table th.text-center {
            text-align: center;
        }
        
        .items-table th.text-right {
            text-align: right;
        }
        
        .items-table td {
            padding: 14px 15px;
            border-bottom: 1px solid #f0f4f8;
            font-size: 12px;
            color: #1A1A2E;
            white-space: nowrap;
        }
        
        .items-table .item-name {
            font-weight: 600;
            color: #0C4A6E;
            white-space: normal;
        }
        
        .items-table .text-center {
            text-align: center;
        }
        
        .items-table .text-right {
            text-align: right;
            font-weight: 600;
        }
        
        .items-table tbody tr:hover {
            background: #f0f7fc;
        }
        
        /* Summary Section */
        .summary-section {
            display: flex;
            justify-content: space-between;
            margin: 0;
            padding: 30px 40px;
            background: white;
        }
        
        .summary-placeholder {
            flex: 1;
        }
        
        .summary-box {
            width: 300px;
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            font-size: 12px;
            border-bottom: 1px solid #e8eef4;
        }
        
        .summary-row .label {
            color: #555;
            font-weight: 500;
        }
        
        .summary-row .value {
            color: #1A1A2E;
            font-weight: 600;
        }
        
        .summary-row.total {
            background: linear-gradient(135deg, #0C4A6E 0%, #0F5D7D 100%);
            color: white;
            padding: 14px 12px;
            margin-top: 10px;
            border-radius: 8px;
            border: none;
            font-size: 13px;
        }
        
        .summary-row.total .label,
        .summary-row.total .value {
            color: #86BDDA;
            font-weight: bold;
        }
        
        .summary-row.discount {
            color: #E74C3C;
        }
        
        .summary-row.discount .label,
        .summary-row.discount .value {
            color: #E74C3C;
            font-weight: 600;
        }
        
        /* Footer Section */
        .footer-section {
            margin-top: 0;
            padding: 30px 40px;
            border-top: 1px solid #e8eef4;
            background: #f8fafb;
        }
        
        .footer-content {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            font-size: 11px;
        }
        
        .footer-col {
            flex: 1;
        }
        
        .footer-col h4 {
            font-size: 11px;
            font-weight: bold;
            color: #0C4A6E;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }
        
        .footer-col p {
            color: #555;
            margin-bottom: 4px;
            line-height: 1.6;
        }
        
        .footer-message {
            background: linear-gradient(135deg, #0C4A6E 0%, #0F5D7D 100%);
            color: #86BDDA;
            padding: 16px;
            text-align: center;
            border-radius: 8px;
            font-size: 12px;
            font-weight: bold;
            margin-top: 20px;
        }
        
        .authorized-signature {
            display: flex;
            justify-content: flex-end;
            margin-top: 30px;
            text-align: center;
        }
        
        .signature-line {
            border-top: 2px solid #0C4A6E;
            padding-top: 8px;
            font-size: 11px;
            color: #555;
            min-width: 150px;
            font-weight: 600;
        }
        
        /* Print Styles */
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
                max-width: 100%;
                padding: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header with Logo -->
        <div class="header">
            <div class="header-left">
                <div class="logo-placeholder">{{LOGO}}</div>
                <div class="header-text">
                    <h1>INVOICE</h1>
                    <p>{{HEADER}}</p>
                    <div class="header-contact">{{CONTACT_INFO}}</div>
                </div>
            </div>
            <div class="header-right">
                <div class="company-name">CEYLUX</div>
                <div class="invoice-number">
                    <span class="label">Invoice #:</span>
                    <span class="value">{{INVOICE_ID}}</span>
                </div>
                <div class="date">
                    <span>{{DATE}}</span>
                </div>
            </div>
        </div>
        
        <!-- Bill To Section -->
        <div class="bill-to">
            <div class="bill-to-section">
                <h3>Bill To:</h3>
                <div class="customer-name">{{CUSTOMER_NAME}}</div>
                <div class="address">{{CUSTOMER_ADDRESS}}</div>
                <div class="phone">{{CUSTOMER_PHONE}}</div>
            </div>
            <div class="bill-to-section" style="text-align: center;">
                <h3>Delivery & Payment:</h3>
                <div class="address" style="font-weight: 600;">Delivery: {{DELIVERY_METHOD}}</div>
                <div class="address" style="font-weight: 600;">Payment: {{PAYMENT_METHOD}}</div>
            </div>
            <div class="bill-to-section" style="text-align: right;">
                <h3>Status:</h3>
                <div style="background: linear-gradient(135deg, #86BDDA 0%, #5BA3C7 100%); color: white; padding: 8px 16px; border-radius: 6px; display: inline-block; font-weight: bold; font-size: 12px;">{{STATUS}}</div>
            </div>
        </div>
        
        <!-- Items Table -->
        <div style="padding: 0 40px;">
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width: 28%;">Item Description</th>
                    <th style="width: 11%;" class="text-center">Qty</th>
                    <th style="width: 19%;" class="text-right">Price</th>
                    <th style="width: 19%;" class="text-right">Discount</th>
                    <th style="width: 23%;" class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                {{ITEMS}}
            </tbody>
        </table>
        </div>
        
        <!-- Summary Section -->
        <div class="summary-section">
            <div class="summary-placeholder"></div>
            <div class="summary-box">
                <div class="summary-row">
                    <span class="label">Subtotal:</span>
                    <span class="value">Rs. {{SUBTOTAL}}</span>
                </div>
                {{#ITEM_DISCOUNTS}}
                <div class="summary-row discount">
                    <span class="label">Item Discounts:</span>
                    <span class="value">- Rs. {{ITEM_DISCOUNTS}}</span>
                </div>
                {{/ITEM_DISCOUNTS}}
                {{#BILL_DISCOUNT}}
                <div class="summary-row discount">
                    <span class="label">Bill Discount ({{BILL_DISCOUNT_PERCENT}}%):</span>
                    <span class="value">- Rs. {{BILL_DISCOUNT}}</span>
                </div>
                {{/BILL_DISCOUNT}}
                {{#LOYALTY_DISCOUNT}}
                <div class="summary-row discount">
                    <span class="label">Loyalty Discount ({{LOYALTY_DISCOUNT_PERCENT}}%):</span>
                    <span class="value">- Rs. {{LOYALTY_DISCOUNT}}</span>
                </div>
                {{/LOYALTY_DISCOUNT}}
                <div class="summary-row total">
                    <span class="label">TOTAL</span>
                    <span class="value">Rs. {{TOTAL}}</span>
                </div>
            </div>
        </div>
        
        <!-- Footer Section -->
        <div class="footer-section">
            <div class="footer-content">
                <div class="footer-col">
                    <h4>Terms</h4>
                    <p>All sales are final</p>
                    <p>Return within 7 days</p>
                </div>
                <div class="footer-col">
                    <h4>Payment</h4>
                    <p>Cash/Card accepted</p>
                    <p>Installments available</p>
                </div>
                <div class="footer-col">
                    <h4>Questions?</h4>
                    <p>Mobile: {{CONTACT_INFO}}</p>
                </div>
            </div>
            
            <div class="footer-message">{{FOOTER}}</div>
            
            <div class="authorized-signature">
                <div class="signature-line">Authorized Signature</div>
            </div>
        </div>
    </div>
</body>
</html>
''';

  static Future<String?> _getHeader() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('invoice_header') ?? 'CEYLUX Fashion';
  }

  static Future<String?> _getFooter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('invoice_footer') ?? 'Thank you for shopping with CEYLUX Fashion!';
  }

  static Future<String?> _getContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('invoice_contact') ?? '';
  }

  static Future<Uint8List?> _getLogoBitmap() async {
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('invoice_logo_path');
    
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _getTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final templatePath = prefs.getString('receipt_template_path');
    
    if (templatePath != null && templatePath.isNotEmpty) {
      try {
        final file = File(templatePath);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (_) {}
    }
    return null;
  }

  // Generate HTML content with invoice data - render to string for display/export
  static Future<String> _generateHTMLFromTemplate(String htmlTemplate, AppOrder order) async {
    final header = await _getHeader();
    final footer = await _getFooter();
    final contact = await _getContactInfo();
    
    int subtotal = order.items.fold<int>(0, (sum, item) => sum + item.subtotal);
    int itemDiscounts = order.items.fold<int>(0, (sum, item) => sum + item.discountAmount);
    int billDiscountAmount = ((subtotal - itemDiscounts) * order.discountPercentage) ~/ 100;
    int afterBillDiscount = subtotal - itemDiscounts - billDiscountAmount;
    int loyaltyDiscountAmount = (afterBillDiscount * order.loyaltyDiscount) ~/ 100;
    int totalDiscount = itemDiscounts + billDiscountAmount + loyaltyDiscountAmount;
    int calculatedTotal = subtotal - totalDiscount;
    
    // Generate items HTML rows with size info included
    String itemsHtml = order.items.map((item) => '''
        <tr>
          <td class="item-name">${item.name}${item.size.isNotEmpty ? ' [${item.size}]' : ''}</td>
          <td class="text-center">${item.qty}</td>
          <td class="text-right">Rs. ${NumberFormat('#,###').format(item.price)}</td>
          <td class="text-right discount-cell">${item.discountAmount > 0 ? 'Rs. ${NumberFormat('#,###').format(item.discountAmount)}' : '-'}</td>
          <td class="text-right">Rs. ${NumberFormat('#,###').format(item.total)}</td>
        </tr>
    ''').join('');
    
    // Replace template variables
    String html = htmlTemplate;
    html = html.replaceAll('{{LOGO}}', 'LOGO');
    html = html.replaceAll('{{HEADER}}', header ?? 'CEYLUX Fashion Boutique');
    html = html.replaceAll('{{DELIVERY_METHOD}}', order.deliveryMethodName ?? 'Not selected');
    html = html.replaceAll('{{PAYMENT_METHOD}}', order.paymentMethodName ?? 'Not selected');
    html = html.replaceAll('Email: {{CONTACT_INFO}}', 'Mobile: {{CONTACT_INFO}}');
    html = html.replaceAll('{{CONTACT_INFO}}', contact ?? '');
    html = html.replaceAll('{{INVOICE_ID}}', order.id);
    html = html.replaceAll('{{DATE}}', order.date);
    html = html.replaceAll('{{CUSTOMER_NAME}}', order.customerName);
    html = html.replaceAll('{{CUSTOMER_ADDRESS}}', order.customerAddress ?? '');
    html = html.replaceAll('{{CUSTOMER_PHONE}}', order.customerPhone ?? '');
    html = html.replaceAll('{{STATUS}}', order.status);
    html = html.replaceAll('{{ITEMS}}', itemsHtml);
    html = html.replaceAll('{{SUBTOTAL}}', NumberFormat('#,###').format(subtotal));
    
    // Handle item discounts conditional block
    if (itemDiscounts > 0) {
      html = html.replaceAll('{{#ITEM_DISCOUNTS}}', '');
      html = html.replaceAll('{{/ITEM_DISCOUNTS}}', '');
      html = html.replaceAll('{{ITEM_DISCOUNTS}}', NumberFormat('#,###').format(itemDiscounts));
    } else {
      html = html.replaceAll(RegExp(r'\{\{#ITEM_DISCOUNTS\}\}.*?\{\{/ITEM_DISCOUNTS\}\}', dotAll: true), '');
    }
    
    // Handle bill discount conditional block
    if (billDiscountAmount > 0) {
      html = html.replaceAll('{{#BILL_DISCOUNT}}', '');
      html = html.replaceAll('{{/BILL_DISCOUNT}}', '');
      html = html.replaceAll('{{BILL_DISCOUNT}}', NumberFormat('#,###').format(billDiscountAmount));
      html = html.replaceAll('{{BILL_DISCOUNT_PERCENT}}', '${order.discountPercentage}');
    } else {
      html = html.replaceAll(RegExp(r'\{\{#BILL_DISCOUNT\}\}.*?\{\{/BILL_DISCOUNT\}\}', dotAll: true), '');
    }
    
    // Handle loyalty discount conditional block
    if (loyaltyDiscountAmount > 0) {
      html = html.replaceAll('{{#LOYALTY_DISCOUNT}}', '');
      html = html.replaceAll('{{/LOYALTY_DISCOUNT}}', '');
      html = html.replaceAll('{{LOYALTY_DISCOUNT}}', NumberFormat('#,###').format(loyaltyDiscountAmount));
      html = html.replaceAll('{{LOYALTY_DISCOUNT_PERCENT}}', '${order.loyaltyDiscount}');
    } else {
      html = html.replaceAll(RegExp(r'\{\{#LOYALTY_DISCOUNT\}\}.*?\{\{/LOYALTY_DISCOUNT\}\}', dotAll: true), '');
    }
    
    html = html.replaceAll('{{TOTAL}}', NumberFormat('#,###').format(calculatedTotal));
    html = html.replaceAll('{{FOOTER}}', footer ?? '');
    
    return html;
  }

  static pw.Document _generatePDF(AppOrder order, String htmlContent, {Uint8List? logoBitmap}) {
    final pdf = pw.Document();
    
    // Parse HTML using html_parser
    final doc = html_parser.parse(htmlContent);
    final container = doc.querySelector('.container') ?? doc.body ?? doc.documentElement!;
    
    // Parse style block
    final styleElement = doc.querySelector('style');
    final cssRules = styleElement != null ? CSSParser.parse(styleElement.text) : <CSSRule>[];
    
    // Recursively convert elements to widgets starting from container
    final rootWidget = _buildElement(container, cssRules, logoBitmap);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.SizedBox(
            width: double.infinity,
            child: rootWidget,
          );
        },
      ),
    );
    
    return pdf;
  }

  static pw.Widget _buildElement(dom.Element element, List<CSSRule> cssRules, Uint8List? logoBitmap, {pw.TextStyle? parentStyle}) {
    final styles = _getElementStyles(element, cssRules);
    
    // Parse alignment & text alignment
    final textAlign = _parseTextAlign(styles['text-align']);
    
    // Inherit text style properties
    final color = _parseColor(styles['color']) ?? parentStyle?.color ?? PdfColors.black;
    
    double fontSize = 11.0;
    final fontSizeVal = styles['font-size'];
    if (fontSizeVal != null) {
      final match = RegExp(r'(\d+)').firstMatch(fontSizeVal);
      if (match != null) {
        fontSize = double.parse(match.group(0)!);
        // Scale down large header fonts slightly for PDF format
        if (fontSize > 24) fontSize = fontSize * 0.75;
      }
    } else if (parentStyle != null) {
      fontSize = parentStyle.fontSize ?? 11.0;
    }
    
    pw.FontWeight fontWeight = pw.FontWeight.normal;
    final fontWeightVal = styles['font-weight'];
    if (fontWeightVal != null) {
      if (fontWeightVal == 'bold' || fontWeightVal == '700' || fontWeightVal == '800' || fontWeightVal == '600') {
        fontWeight = pw.FontWeight.bold;
      }
    } else if (parentStyle != null) {
      fontWeight = parentStyle.fontWeight ?? pw.FontWeight.normal;
    }
    
    final currentStyle = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
    
    // Determine tag name
    final tag = element.localName;
    
    // Custom element handling: logo placeholder
    if (element.classes.contains('logo-placeholder')) {
      if (logoBitmap != null) {
        return pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: const PdfColor(1.0, 1.0, 1.0, 0.15),
            border: pw.Border.all(color: const PdfColor(1.0, 1.0, 1.0, 0.3), width: 1.5),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          alignment: pw.Alignment.center,
          child: pw.Image(pw.MemoryImage(logoBitmap), fit: pw.BoxFit.cover),
        );
      }
    }
    
    // Handle table elements
    if (tag == 'table') {
      return _buildTable(element, cssRules, logoBitmap, currentStyle);
    }
    
    // Check if it's a leaf node or contains only text nodes
    final hasElementChildren = element.children.isNotEmpty;
    
    // Parse margins, paddings & decorations
    var padding = _parseMarginOrPadding(styles, 'padding');
    final margin = _parseMarginOrPadding(styles, 'margin');
    final decoration = _parseDecoration(styles);
    
    pw.Widget widget;
    
    if (!hasElementChildren) {
      final text = element.text.trim();
      widget = pw.Text(
        text,
        style: currentStyle,
        textAlign: textAlign,
      );
      
      final align = _parseAlignment(styles);
      if (padding != null || decoration != null || margin != null || align != null) {
        widget = pw.Container(
          padding: padding,
          margin: margin,
          decoration: decoration,
          alignment: align,
          child: widget,
        );
      }
    } else {
      // Convert children recursively
      final children = <pw.Widget>[];
      for (final child in element.children) {
        final childWidget = _buildElement(child, cssRules, logoBitmap, parentStyle: currentStyle);
        children.add(childWidget);
      }
      
      // Determine layout direction (row or column)
      final isFlex = styles['display'] == 'flex' || 
                     element.classes.contains('header') ||
                     element.classes.contains('header-left') ||
                     element.classes.contains('bill-to') ||
                     element.classes.contains('summary-section') ||
                     element.classes.contains('summary-row') ||
                     element.classes.contains('footer-content') ||
                     element.classes.contains('authorized-signature');
                     
      final flexDirectionVal = styles['flex-direction'];
      final isRow = isFlex && flexDirectionVal != 'column';
      
      // Parse gap
      final gapAttr = styles['gap'];
      double gap = 0;
      if (gapAttr != null) {
        final match = RegExp(r'(\d+)').firstMatch(gapAttr);
        if (match != null) gap = double.parse(match.group(0)!);
      }
      
      if (isRow) {
        pw.MainAxisAlignment mainAlign = pw.MainAxisAlignment.start;
        final justify = styles['justify-content'];
        if (justify == 'space-between') {
          mainAlign = pw.MainAxisAlignment.spaceBetween;
        } else if (justify == 'flex-end' || justify == 'right') {
          mainAlign = pw.MainAxisAlignment.end;
        } else if (justify == 'center') {
          mainAlign = pw.MainAxisAlignment.center;
        }
        
        pw.CrossAxisAlignment crossAlign = pw.CrossAxisAlignment.center;
        final alignSelf = styles['align-items'];
        if (alignSelf == 'flex-start' || alignSelf == 'start') {
          crossAlign = pw.CrossAxisAlignment.start;
        } else if (alignSelf == 'flex-end' || alignSelf == 'end') {
          crossAlign = pw.CrossAxisAlignment.end;
        }
        
        // Add gap spaces
        final rowChildren = <pw.Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0 && gap > 0) {
            rowChildren.add(pw.SizedBox(width: gap));
          }
          rowChildren.add(children[i]);
        }
        
        widget = pw.Row(
          children: rowChildren,
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: crossAlign,
        );
      } else {
        pw.CrossAxisAlignment crossAlign = pw.CrossAxisAlignment.start;
        final align = styles['text-align'];
        if (align == 'right') {
          crossAlign = pw.CrossAxisAlignment.end;
        } else if (align == 'center') {
          crossAlign = pw.CrossAxisAlignment.center;
        }
        
        // Add gap spaces
        final colChildren = <pw.Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0 && gap > 0) {
            colChildren.add(pw.SizedBox(height: gap));
          }
          colChildren.add(children[i]);
        }
        
        widget = pw.Column(
          children: colChildren,
          crossAxisAlignment: crossAlign,
        );
      }
      
      // Special Header shape handling to match HTML decoration
      if (element.classes.contains('header')) {
        final headerContent = pw.Row(
          children: children,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
        );
        
        PdfColor accentColor = const PdfColor(1.0, 1.0, 1.0, 0.08);
        final bg = styles['background'] ?? styles['background-color'] ?? '';
        if (bg.contains('#0C4A6E') || bg.contains('#0c4a6e') || bg.contains('#0F5D7D') || bg.contains('#0f5d7d')) {
          accentColor = PdfColor.fromHex('#1d668c');
        } else if (bg.contains('#1E1E24') || bg.contains('#1e1e24') || bg.contains('#2D2D37') || bg.contains('#2d2d37')) {
          accentColor = PdfColor.fromHex('#37312C');
        } else {
          final hexRegex = RegExp(r'#([0-9a-fA-F]{6})');
          final match = hexRegex.firstMatch(bg);
          if (match != null) {
            final baseColor = PdfColor.fromHex(match.group(0)!);
            accentColor = PdfColor(
              baseColor.red * 0.85 + 0.15,
              baseColor.green * 0.85 + 0.15,
              baseColor.blue * 0.85 + 0.15,
            );
          }
        }

        widget = pw.Stack(
          alignment: pw.Alignment.topLeft,
          children: [
            pw.Positioned(
              bottom: -60,
              right: -120,
              child: pw.Container(
                width: 350,
                height: 250,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(175),
                ),
              ),
            ),
            pw.Padding(
              padding: padding ?? const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: headerContent,
            ),
          ],
        );
        padding = null; // Clear padding from outer container to avoid double-padding
      }
      
      // Wrap in container if it has styling/spacing/sizes
      final widthAttr = styles['width'];
      double? width;
      if (widthAttr != null) {
        final pxMatch = RegExp(r'(\d+)px').firstMatch(widthAttr);
        if (pxMatch != null) {
          width = double.parse(pxMatch.group(1)!);
        }
      }
      
      final heightAttr = styles['height'];
      double? height;
      if (heightAttr != null) {
        final pxMatch = RegExp(r'(\d+)px').firstMatch(heightAttr);
        if (pxMatch != null) {
          height = double.parse(pxMatch.group(1)!);
        }
      }
      
      final align = _parseAlignment(styles);
      if (padding != null || decoration != null || margin != null || width != null || height != null || align != null) {
        widget = pw.Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: decoration,
          alignment: align,
          child: widget,
        );
      }
    }
    
    // Handle flex / expanded (note: header-text is removed from Expanded wrap to prevent overflow)
    final flexVal = styles['flex'];
    if (flexVal == '1' || 
        element.classes.contains('summary-placeholder') || 
        element.classes.contains('footer-col') || 
        element.classes.contains('bill-to-section')) {
      widget = pw.Expanded(child: widget);
    }
    
    return widget;
  }

  static pw.Widget _buildTable(dom.Element tableElement, List<CSSRule> cssRules, Uint8List? logoBitmap, pw.TextStyle parentStyle) {
    final rows = <pw.TableRow>[];
    final columnWidths = <int, pw.TableColumnWidth>{};
    
    final trElements = tableElement.querySelectorAll('tr');
    
    for (var rowIndex = 0; rowIndex < trElements.length; rowIndex++) {
      final tr = trElements[rowIndex];
      final cells = tr.querySelectorAll('th, td');
      final rowChildren = <pw.Widget>[];
      
      final trStyles = _getElementStyles(tr, cssRules);
      final parent = tr.parent;
      var trBgColor = _parseColor(trStyles['background'] ?? trStyles['background-color']);
      if (trBgColor == null && parent != null) {
        final parentStyles = _getElementStyles(parent, cssRules);
        trBgColor = _parseColor(parentStyles['background'] ?? parentStyles['background-color']);
      }
      
      for (var colIndex = 0; colIndex < cells.length; colIndex++) {
        final cell = cells[colIndex];
        final cellStyles = _getElementStyles(cell, cssRules);
        
        final inheritedStyle = _resolveInheritedStyle(cell, cssRules, parentStyle);
        
        final cellWidget = _buildElement(cell, cssRules, logoBitmap, parentStyle: inheritedStyle);
        rowChildren.add(cellWidget);
        
        if (rowIndex == 0) {
          final widthAttr = cellStyles['width'];
          if (widthAttr != null) {
            final percentageMatch = RegExp(r'(\d+)%').firstMatch(widthAttr);
            if (percentageMatch != null) {
              final percentage = double.parse(percentageMatch.group(1)!) / 100.0;
              columnWidths[colIndex] = pw.FractionColumnWidth(percentage);
            } else {
              final pxMatch = RegExp(r'(\d+)px').firstMatch(widthAttr);
              if (pxMatch != null) {
                final width = double.parse(pxMatch.group(1)!);
                columnWidths[colIndex] = pw.FixedColumnWidth(width);
              }
            }
          }
        }
      }
      
      rows.add(
        pw.TableRow(
          children: rowChildren,
          decoration: trBgColor != null ? pw.BoxDecoration(color: trBgColor) : null,
        ),
      );
    }
    
    return pw.Table(
      children: rows,
      columnWidths: columnWidths.isNotEmpty ? columnWidths : null,
    );
  }

  static pw.TextStyle _resolveInheritedStyle(dom.Element element, List<CSSRule> cssRules, pw.TextStyle baseStyle) {
    final path = <dom.Element>[];
    var curr = element.parent;
    while (curr != null && curr.localName != 'table') {
      path.add(curr);
      curr = curr.parent;
    }
    
    var style = baseStyle;
    for (final el in path.reversed) {
      final elStyles = _getElementStyles(el, cssRules);
      style = _mergeTextStyle(elStyles, style);
    }
    return style;
  }

  static pw.TextStyle _mergeTextStyle(Map<String, String> styles, pw.TextStyle parentStyle) {
    final color = _parseColor(styles['color']) ?? parentStyle.color ?? PdfColors.black;
    double fontSize = parentStyle.fontSize ?? 11.0;
    final fontSizeVal = styles['font-size'];
    if (fontSizeVal != null) {
      final match = RegExp(r'(\d+)').firstMatch(fontSizeVal);
      if (match != null) {
        fontSize = double.parse(match.group(0)!);
        if (fontSize > 24) fontSize = fontSize * 0.75;
      }
    }
    pw.FontWeight fontWeight = parentStyle.fontWeight ?? pw.FontWeight.normal;
    final fontWeightVal = styles['font-weight'];
    if (fontWeightVal != null) {
      if (fontWeightVal == 'bold' || fontWeightVal == '700' || fontWeightVal == '800' || fontWeightVal == '600') {
        fontWeight = pw.FontWeight.bold;
      }
    }
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static Map<String, String> _getElementStyles(dom.Element element, List<CSSRule> cssRules) {
    final merged = <String, String>{};
    
    for (final rule in cssRules) {
      if (_matchesSelector(element, rule.selector)) {
        merged.addAll(rule.style.properties);
      }
    }
    
    final inlineStyle = element.attributes['style'];
    if (inlineStyle != null) {
      final ruleRegExp = RegExp(r'([^:\s]+)\s*:\s*([^;]+);?');
      final matches = ruleRegExp.allMatches(inlineStyle);
      for (final match in matches) {
        final propName = match.group(1)!.trim().toLowerCase();
        final propVal = match.group(2)!.trim();
        merged[propName] = propVal;
      }
    }
    
    return merged;
  }

  static bool _matchesSelector(dom.Element element, String selector) {
    selector = selector.replaceAll('>', ' ');
    if (selector.contains(' ')) {
      final parts = selector.split(RegExp(r'\s+'));
      var currentElement = element;
      for (var i = parts.length - 1; i >= 0; i--) {
        final part = parts[i];
        if (!_matchesSingleSelector(currentElement, part)) {
          return false;
        }
        if (i > 0) {
          var parent = currentElement.parent;
          while (parent != null && !_matchesSingleSelector(parent, parts[i - 1])) {
            parent = parent.parent;
          }
          if (parent == null) return false;
          currentElement = parent;
          i--;
        }
      }
      return true;
    }
    return _matchesSingleSelector(element, selector);
  }

  static bool _matchesSingleSelector(dom.Element element, String selector) {
    if (selector == '*') return true;
    if (selector.startsWith('.')) {
      final classes = selector.substring(1).split('.');
      final elementClasses = element.classes;
      return classes.every((c) => elementClasses.contains(c));
    }
    return element.localName == selector;
  }

  static PdfColor? _parseColor(String? value) {
    if (value == null) return null;
    value = value.trim().toLowerCase();
    if (value == 'white' || value == '#fff' || value == '#ffffff') {
      return PdfColors.white;
    }
    if (value == 'black' || value == '#000' || value == '#000000') {
      return PdfColors.black;
    }
    if (value == 'transparent') {
      return null;
    }
    final hexRegex = RegExp(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})');
    final match = hexRegex.firstMatch(value);
    if (match != null) {
      return PdfColor.fromHex(match.group(0)!);
    }
    return null;
  }

  static pw.BoxDecoration? _parseDecoration(Map<String, String> styles) {
    final bg = styles['background'] ?? styles['background-color'];
    if (bg == null) return null;
    
    if (bg.contains('linear-gradient')) {
      final hexRegex = RegExp(r'#([0-9a-fA-F]{6})');
      final matches = hexRegex.allMatches(bg).map((m) => m.group(0)!).toList();
      if (matches.length >= 2) {
        return pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColor.fromHex(matches[0]), PdfColor.fromHex(matches[1])],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
          borderRadius: _parseBorderRadius(styles['border-radius']),
        );
      }
    }
    
    final color = _parseColor(bg);
    final borderRadius = _parseBorderRadius(styles['border-radius']);
    final border = _parseBorder(styles);
    
    if (color != null || borderRadius != null || border != null) {
      return pw.BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
      );
    }
    return null;
  }

  static pw.BorderRadius? _parseBorderRadius(String? value) {
    if (value == null) return null;
    final numRegex = RegExp(r'(\d+)');
    final match = numRegex.firstMatch(value);
    if (match != null) {
      final radius = double.parse(match.group(0)!);
      return pw.BorderRadius.circular(radius);
    }
    return null;
  }

  static pw.Border? _parseBorder(Map<String, String> styles) {
    final borderAttr = styles['border'];
    final borderBottomAttr = styles['border-bottom'];
    final borderTopAttr = styles['border-top'];
    
    pw.BorderSide? _parseBorderSide(String? borderVal) {
      if (borderVal == null || borderVal == 'none') return null;
      final widthMatch = RegExp(r'(\d+)px').firstMatch(borderVal);
      final width = widthMatch != null ? double.parse(widthMatch.group(1)!) : 1.0;
      final color = _parseColor(borderVal) ?? PdfColors.grey;
      return pw.BorderSide(width: width, color: color);
    }
    
    if (borderAttr != null) {
      final side = _parseBorderSide(borderAttr);
      if (side != null) return pw.Border.all(color: side.color, width: side.width);
    }
    
    final top = _parseBorderSide(borderTopAttr);
    final bottom = _parseBorderSide(borderBottomAttr);
    if (top != null || bottom != null) {
      return pw.Border(
        top: top ?? pw.BorderSide.none,
        bottom: bottom ?? pw.BorderSide.none,
        left: pw.BorderSide.none,
        right: pw.BorderSide.none,
      );
    }
    return null;
  }

  static pw.EdgeInsets? _parseMarginOrPadding(Map<String, String> styles, String prefix) {
    final all = styles[prefix];
    final top = styles['$prefix-top'];
    final bottom = styles['$prefix-bottom'];
    final left = styles['$prefix-left'];
    final right = styles['$prefix-right'];
    
    double? valTop, valBottom, valLeft, valRight;
    
    double? _parseSingle(String? val) {
      if (val == null) return null;
      final match = RegExp(r'(-?\d+)').firstMatch(val);
      return match != null ? double.parse(match.group(1)!) : null;
    }
    
    if (all != null) {
      final values = RegExp(r'(-?\d+)').allMatches(all).map((m) => double.parse(m.group(0)!)).toList();
      if (values.isNotEmpty) {
        if (values.length == 1) {
          valTop = valBottom = valLeft = valRight = values[0];
        } else if (values.length == 2) {
          valTop = valBottom = values[0];
          valLeft = valRight = values[1];
        } else if (values.length >= 4) {
          valTop = values[0];
          valRight = values[1];
          valBottom = values[2];
          valLeft = values[3];
        }
      }
    }
    
    valTop = (_parseSingle(top) ?? valTop ?? 0.0) * 0.5;
    valBottom = (_parseSingle(bottom) ?? valBottom ?? 0.0) * 0.5;
    valLeft = _parseSingle(left) ?? valLeft ?? 0.0;
    valRight = _parseSingle(right) ?? valRight ?? 0.0;
    
    if (valTop == 0 && valBottom == 0 && valLeft == 0 && valRight == 0) return null;
    return pw.EdgeInsets.fromLTRB(valLeft, valTop, valRight, valBottom);
  }

  static pw.Alignment? _parseAlignment(Map<String, String> styles) {
    final textAlign = styles['text-align'];
    if (textAlign == 'right') return pw.Alignment.centerRight;
    if (textAlign == 'center') return pw.Alignment.center;
    if (textAlign == 'left') return pw.Alignment.centerLeft;
    return null;
  }

  static pw.TextAlign _parseTextAlign(String? value) {
    if (value == null) return pw.TextAlign.left;
    if (value == 'center') return pw.TextAlign.center;
    if (value == 'right') return pw.TextAlign.right;
    if (value == 'justify') return pw.TextAlign.justify;
    return pw.TextAlign.left;
  }

  static Future<void> shareInvoice(AppOrder order, {String? phone}) async {
    final template = await _getTemplate() ?? defaultTemplate;
    final html = await _generateHTMLFromTemplate(template, order);
    final logoBitmap = await _getLogoBitmap();
    
    final pdf = _generatePDF(order, html, logoBitmap: logoBitmap);

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/CEYLUX_Invoice_${order.id}.pdf');
    await file.writeAsBytes(bytes);

    final msg = '📄 *Invoice from CEYLUX* 📄\n\n'
      'Order: *${order.id}*\n'
      'Customer: ${order.customerName}\n'
      '${order.items.map((i) => '• ${i.name} [${i.size}] x${i.qty} — Rs. ${NumberFormat('#,###').format(i.subtotal)}').join('\n')}'
      '\n\n💰 *Total: Rs. ${NumberFormat('#,###').format(order.total)}*\n\n'
      'PDF receipt attached. Thank you for shopping with CEYLUX! 🛍️';

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'CEYLUX Invoice - ${order.id}',
      text: msg,
    );
  }

  static Future<void> downloadInvoice(AppOrder order) async {
    final template = await _getTemplate() ?? defaultTemplate;
    final html = await _generateHTMLFromTemplate(template, order);
    final logoBitmap = await _getLogoBitmap();
    
    final pdf = _generatePDF(order, html, logoBitmap: logoBitmap);

    final bytes = await pdf.save();

    String dir = '';
    if (Platform.isAndroid) {
      dir = '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      dir = docsDir.path;
    } else if (Platform.isWindows) {
      dir = '${Platform.environment['USERPROFILE']}\\Downloads';
    } else if (Platform.isLinux) {
      dir = '${Platform.environment['HOME']}/Downloads';
    } else if (Platform.isMacOS) {
      dir = '${Platform.environment['HOME']}/Downloads';
    }

    final file = File('$dir/CEYLUX_Invoice_${order.id}.pdf');
    await file.writeAsBytes(bytes);
  }

  // Download HTML Receipt
  static Future<String?> downloadHTMLReceipt(AppOrder order) async {
    try {
      final template = await _getTemplate() ?? defaultTemplate;
      final html = await _generateHTMLFromTemplate(template, order);

      String dir = '';
      if (Platform.isAndroid) {
        dir = '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        dir = docsDir.path;
      } else if (Platform.isWindows) {
        dir = '${Platform.environment['USERPROFILE']}\\Downloads';
      } else if (Platform.isLinux) {
        dir = '${Platform.environment['HOME']}/Downloads';
      } else if (Platform.isMacOS) {
        dir = '${Platform.environment['HOME']}/Downloads';
      }

      final file = File('$dir/CEYLUX_Receipt_${order.id}.html');
      await file.writeAsString(html);
      return file.path;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Get HTML Receipt for Display
  static Future<String?> getHTMLReceipt(AppOrder order) async {
    try {
      final template = await _getTemplate() ?? defaultTemplate;
      return await _generateHTMLFromTemplate(template, order);
    } catch (e) {
      return null;
    }
  }

  // Share HTML Receipt
  static Future<void> shareHTMLReceipt(AppOrder order) async {
    try {
      final template = await _getTemplate() ?? defaultTemplate;
      final html = await _generateHTMLFromTemplate(template, order);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/CEYLUX_Receipt_${order.id}.html');
      await file.writeAsString(html);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'CEYLUX Receipt - ${order.id}',
        text: 'Receipt from CEYLUX for order ${order.id}',
      );
    } catch (_) {}
  }

  static Future<File> generateInvoicePDFFile(AppOrder order) async {
    final template = await _getTemplate() ?? defaultTemplate;
    final html = await _generateHTMLFromTemplate(template, order);
    final logoBitmap = await _getLogoBitmap();
    
    final pdf = _generatePDF(order, html, logoBitmap: logoBitmap);
    final bytes = await pdf.save();
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/CEYLUX_Invoice_${order.id}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}

// ── CSS & HTML to PDF Helper Classes ─────────────────────────────────────────

class CSSStyle {
  final Map<String, String> properties;
  CSSStyle(this.properties);
}

class CSSRule {
  final String selector;
  final CSSStyle style;
  CSSRule(this.selector, this.style);
}

class CSSParser {
  static List<CSSRule> parse(String cssContent) {
    final rules = <CSSRule>[];
    cssContent = cssContent.replaceAll(RegExp(r'\/\*[\s\S]*?\*\/'), '');
    
    // Strip out @media, @keyframes, @supports blocks (which can have nested curly braces)
    var cleanCss = '';
    var i = 0;
    while (i < cssContent.length) {
      if (cssContent.startsWith('@media', i) || 
          cssContent.startsWith('@keyframes', i) || 
          cssContent.startsWith('@supports', i)) {
        final blockStart = cssContent.indexOf('{', i);
        if (blockStart != -1) {
          var braceCount = 1;
          var j = blockStart + 1;
          while (j < cssContent.length && braceCount > 0) {
            if (cssContent[j] == '{') {
              braceCount++;
            } else if (cssContent[j] == '}') {
              braceCount--;
            }
            j++;
          }
          i = j;
          continue;
        }
      }
      cleanCss += cssContent[i];
      i++;
    }
    cssContent = cleanCss;
    
    final regExp = RegExp(r'([^{]+)\s*\{\s*([^}]+)\s*\}');
    final matches = regExp.allMatches(cssContent);
    for (final match in matches) {
      final selectorText = match.group(1)!;
      final rulesBlock = match.group(2)!;
      
      final styleProps = <String, String>{};
      final ruleRegExp = RegExp(r'([^:\s]+)\s*:\s*([^;]+);?');
      final ruleMatches = ruleRegExp.allMatches(rulesBlock);
      for (final ruleMatch in ruleMatches) {
        final propName = ruleMatch.group(1)!.trim().toLowerCase();
        final propVal = ruleMatch.group(2)!.trim();
        styleProps[propName] = propVal;
      }
      
      final selectors = selectorText.split(',');
      for (var selector in selectors) {
        selector = selector.trim().toLowerCase();
        if (selector.isNotEmpty) {
          rules.add(CSSRule(selector, CSSStyle(styleProps)));
        }
      }
    }
    return rules;
  }
}
