import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class HTMLPreviewWidget extends StatefulWidget {
  final String html;
  final String orderID;

  const HTMLPreviewWidget({
    required this.html,
    required this.orderID,
    super.key,
  });

  @override
  State<HTMLPreviewWidget> createState() => _HTMLPreviewWidgetState();
}

class _HTMLPreviewWidgetState extends State<HTMLPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bg,
      child: Column(
        children: [
          // HTML Content Preview
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: _buildHTMLPreview(widget.html),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a preview of your receipt template. Downloads will use actual order data.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHTMLPreview(String html) {
    // Simple HTML to Widget conversion for preview
    // This extracts visible content from HTML
    try {
      // Remove HTML tags for basic preview
      String plainText = html;
      
      // Remove script and style tags content
      plainText = plainText.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
      plainText = plainText.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
      
      // Remove remaining HTML tags but keep content
      final tagRegExp = RegExp(r'<[^>]*>');
      plainText = plainText.replaceAll(tagRegExp, ' ');
      
      // Clean up extra spaces
      plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      if (plainText.isEmpty) {
        return Text(
          'HTML content will be displayed here when viewed in a browser.\n\nThe receipt will show with full styling including colors, fonts, and layout.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        );
      }
      
      // Show extracted text preview
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template Preview (Text Extract)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plainText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textColor,
              height: 1.6,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Template is ready! Download receipts to see full design.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return Text(
        'Error processing template: $e',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.danger,
        ),
      );
    }
  }
}
