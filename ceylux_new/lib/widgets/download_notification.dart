import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/theme.dart';

enum DownloadStatus { downloading, completed, failed }

class DownloadNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String fileName,
    required Future<File> downloadFuture,
  }) {
    // Dismiss existing banner first if any
    dismiss();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (context) => _DownloadNotificationBanner(
        fileName: fileName,
        downloadFuture: downloadFuture,
        onDismiss: () => dismiss(),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}

class _DownloadNotificationBanner extends StatefulWidget {
  final String fileName;
  final Future<File> downloadFuture;
  final VoidCallback onDismiss;

  const _DownloadNotificationBanner({
    required this.fileName,
    required this.downloadFuture,
    required this.onDismiss,
  });

  @override
  State<_DownloadNotificationBanner> createState() =>
      _DownloadNotificationBannerState();
}

class _DownloadNotificationBannerState
    extends State<_DownloadNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  DownloadStatus _status = DownloadStatus.downloading;
  File? _downloadedFile;
  String _fileSizeText = '';

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final file = await widget.downloadFuture;
      if (!mounted) return;

      final sizeBytes = await file.length();
      final sizeKb = sizeBytes / 1024.0;
      final sizeText = '${sizeKb.toStringAsFixed(1)} KB';

      setState(() {
        _downloadedFile = file;
        _fileSizeText = sizeText;
        _status = DownloadStatus.completed;
      });

      // Auto dismiss after 6 seconds if completed successfully
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _status == DownloadStatus.completed) {
          _closeBanner();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = DownloadStatus.failed;
      });
    }
  }

  Future<void> _openFile() async {
    if (_downloadedFile == null) return;
    try {
      final filePath = _downloadedFile!.path;
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (Platform.isWindows) {
          await Process.run('explorer.exe', [filePath]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [filePath]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [filePath]);
        } else {
          await _shareFile();
        }
      }
    } catch (e) {
      await _shareFile();
    }
  }

  Future<void> _shareFile() async {
    if (_downloadedFile == null) return;
    await Share.shareXFiles(
      [XFile(_downloadedFile!.path, mimeType: 'application/pdf')],
      subject: widget.fileName,
    );
  }

  void _closeBanner() {
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 12;
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth > 600;

    return Positioned(
      top: topPadding,
      left: isDesktop ? null : 16,
      right: isDesktop ? 24 : 16,
      width: isDesktop ? 380 : screenWidth - 32,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withOpacity(0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.card.withOpacity(AppColors.isDark ? 0.78 : 0.88),
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      // File Icon / Status Indicator
                      _buildFileIcon(),
                      const SizedBox(width: 12),

                      // Content details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.fileName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            _buildSubtitle(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action Buttons
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    Color containerColor;
    IconData iconData;
    Color iconColor;

    switch (_status) {
      case DownloadStatus.downloading:
        containerColor = AppColors.gold.withOpacity(0.12);
        iconData = Icons.picture_as_pdf;
        iconColor = AppColors.gold;
        break;
      case DownloadStatus.completed:
        containerColor = AppColors.success.withOpacity(0.12);
        iconData = Icons.check_circle_outline;
        iconColor = AppColors.success;
        break;
      case DownloadStatus.failed:
        containerColor = AppColors.danger.withOpacity(0.12);
        iconData = Icons.error_outline;
        iconColor = AppColors.danger;
        break;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: containerColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    switch (_status) {
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Downloading file...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ),
          ],
        );
      case DownloadStatus.completed:
        return Text(
          'Saved to downloads • $_fileSizeText',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        );
      case DownloadStatus.failed:
        return Text(
          'Failed to download',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  Widget _buildActions() {
    if (_status == DownloadStatus.downloading) {
      return Container(
        margin: const EdgeInsets.only(right: 4),
        width: 18,
        height: 18,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
    }

    if (_status == DownloadStatus.failed) {
      return IconButton(
        onPressed: _closeBanner,
        icon: Icon(Icons.close, color: AppColors.muted, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 16,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Open button
        TextButton(
          onPressed: _openFile,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Open',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Share button
        IconButton(
          onPressed: _shareFile,
          icon: const Icon(Icons.share, color: AppColors.gold, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 16,
        ),
        const SizedBox(width: 6),
        // Close button
        IconButton(
          onPressed: _closeBanner,
          icon: Icon(Icons.close, color: AppColors.muted, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 16,
        ),
      ],
    );
  }
}
