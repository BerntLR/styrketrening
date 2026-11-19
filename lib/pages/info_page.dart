import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_links.dart';
import '../l10n/app_strings.dart';
import '../services/backup_service.dart';
import '../services/tipjar_service.dart';
import '../widgets/watermark.dart';

/// Info page, built from the Karo standard template
/// (_karo_standard/maler/lib/info_page.dart) plus the backup section.
class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final TipJarService _tipjar = TipJarService();
  final BackupService _backup = BackupService();
  final GlobalKey _exportKey = GlobalKey();

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _iapAvailable = false;
  bool _loadingTips = true;
  Map<String, ProductDetails> _tipProducts = <String, ProductDetails>{};

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  Future<void> _initIap() async {
    try {
      _iapAvailable = await _tipjar.isAvailable();
      if (_iapAvailable) {
        _sub = _tipjar.purchaseStream().listen((purchases) async {
          for (final p in purchases) {
            await _tipjar.completeIfNeeded(p);
            if (!mounted) continue;
            if (p.status == PurchaseStatus.purchased) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.of(context).thankYouForSupport),
                ),
              );
            }
          }
        });
        _tipProducts = await _tipjar.loadTipProducts();
      }
    } catch (_) {
      _iapAvailable = false;
    }
    if (!mounted) return;
    setState(() => _loadingTips = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).couldNotOpenLink)),
      );
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppLinks.email,
      query: 'subject=${Uri.encodeComponent(AppStrings.of(context).appName)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).couldNotOpenEmail)),
      );
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Share sheet anchor: the export button (iOS needs one, also on iPhone).
  Rect _shareOrigin() {
    final box = _exportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }

  Future<void> _exportBackup() async {
    final s = AppStrings.of(context);
    final origin = _shareOrigin();
    try {
      final ok = await _backup.exportBackup(
        shareOrigin: origin,
        dialogTitle: s.exportData,
      );
      if (ok) _snack(s.backupExported);
    } catch (_) {
      _snack(s.couldNotExport);
    }
  }

  Future<void> _importBackup() async {
    final s = AppStrings.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.importData),
        content: Text(s.importConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(s.importData),
          ),
        ],
      ),
    );
    if (go != true) return;

    BackupData? data;
    try {
      data = await _backup.pickBackup();
    } catch (_) {
      _snack(s.importFailed);
      return;
    }
    if (data == null) return; // cancelled
    try {
      await _backup.restore(data);
      _snack(s.importDone);
    } catch (_) {
      _snack(s.importFailed);
    }
  }

  Future<void> _donate(String productId) async {
    final p = _tipProducts[productId];
    if (p == null) return;
    await _tipjar.buyTip(p);
  }

  Widget _tipButton(String label, String productId) {
    final enabled = _iapAvailable && _tipProducts.containsKey(productId);
    final price = _tipProducts[productId]?.price;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? () => _donate(productId) : null,
        icon: const Icon(Icons.favorite),
        label: Text(price == null ? label : '$label ($price)'),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _link(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);

    final Widget tipSection;
    if (_loadingTips) {
      tipSection = const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      tipSection = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tipButton(s.donateNok(29), TipJarService.tip29ProductId),
          const SizedBox(height: 8),
          _tipButton(s.donateNok(59), TipJarService.tip59ProductId),
          const SizedBox(height: 8),
          _tipButton(s.donateNok(99), TipJarService.tip99ProductId),
          if (!_iapAvailable || _tipProducts.isEmpty) ...[
            const SizedBox(height: 8),
            Text(s.tipNotAvailable, style: theme.textTheme.bodySmall),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.info), centerTitle: true),
      body: Stack(
        children: [
          const Watermark(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s.appName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(s.infoBody),
              const SizedBox(height: 12),
              _bullet(Icons.swipe, s.swipeHint),
              _bullet(Icons.timer_outlined, s.restTimerHint),
              const SizedBox(height: 20),
              Text(s.backupTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: _exportKey,
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.upload_file),
                      label: Text(s.exportData),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importBackup,
                      icon: const Icon(Icons.download),
                      label: Text(s.importData),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(s.linksTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _link(Icons.mail_outline, s.sendLetter, _emailSupport),
              _link(Icons.public, s.website, () => _openUrl(AppLinks.website)),
              _link(
                Icons.privacy_tip,
                s.privacyPolicy,
                () => _openUrl(AppLinks.privacy),
              ),
              _link(
                Icons.support_agent,
                s.support,
                () => _openUrl(AppLinks.support),
              ),
              _link(Icons.apps, s.moreApps, () => _openUrl(AppLinks.moreApps)),
              const SizedBox(height: 12),
              Text(s.tipTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              tipSection,
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
