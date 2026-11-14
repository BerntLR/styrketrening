import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_links.dart';
import '../l10n/app_strings.dart';
import '../services/backup_service.dart';
import '../services/tipjar_service.dart';
import '../widgets/watermark.dart';

class InfoPage extends StatefulWidget {
  static const String supportEmail = 'post@teambullpeak.com';

  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final BackupService _backup = BackupService();
  final TipJarService _tipjar = TipJarService();

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

    if (!mounted) return;
    setState(() {
      _loadingTips = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).couldNotOpenLink)),
      );
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: InfoPage.supportEmail,
      queryParameters: {'subject': AppStrings.of(context).appName},
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).couldNotOpenEmail)),
      );
    }
  }

  Future<void> _exportBackup() async {
    await _backup.exportBackup(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).backupExported)),
    );
  }

  Future<void> _importBackup() async {
    final ok = await _backup.importBackup();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).dataImported)),
      );
    }
  }

  Future<void> _donate(String productId) async {
    final p = _tipProducts[productId];
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).tipNotAvailable)),
      );
      return;
    }
    await _tipjar.buyTip(p);
  }

  Widget _tipButton({required String label, required String productId}) {
    final enabled = _iapAvailable && _tipProducts.containsKey(productId);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? () => _donate(productId) : null,
        icon: const Icon(Icons.favorite),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final tipSection = _loadingTips
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          )
        : (!_iapAvailable
              ? Text(strings.tipNotAvailable, style: theme.textTheme.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tipButton(
                      label: strings.donateNok(29),
                      productId: TipJarService.tip29ProductId,
                    ),
                    const SizedBox(height: 8),
                    _tipButton(
                      label: strings.donateNok(59),
                      productId: TipJarService.tip59ProductId,
                    ),
                    const SizedBox(height: 8),
                    _tipButton(
                      label: strings.donateNok(99),
                      productId: TipJarService.tip99ProductId,
                    ),
                    if (_tipProducts.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        strings.tipNotAvailable,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ));

    return Scaffold(
      appBar: AppBar(title: Text(strings.info), centerTitle: true),
      body: Stack(
        children: [
          const Watermark(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.appName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(strings.infoBody),

              const SizedBox(height: 8),
              Text(strings.swipeHint, style: theme.textTheme.bodySmall),

              const SizedBox(height: 20),
              Text(
                strings.backupSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.upload_file),
                      label: Text(strings.exportData),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importBackup,
                      icon: const Icon(Icons.download),
                      label: Text(strings.importData),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(strings.linksTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _emailSupport,
                icon: const Icon(Icons.mail_outline),
                label: Text(strings.sendLetter),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl(AppLinks.website),
                icon: const Icon(Icons.public),
                label: Text(strings.website),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl(AppLinks.privacy),
                icon: const Icon(Icons.privacy_tip),
                label: Text(strings.privacyPolicy),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl(AppLinks.support),
                icon: const Icon(Icons.support_agent),
                label: Text(strings.support),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl(AppLinks.moreApps),
                icon: const Icon(Icons.apps),
                label: Text(strings.moreApps),
              ),

              const SizedBox(height: 20),
              Text(strings.tipTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              tipSection,
            ],
          ),
        ],
      ),
    );
  }
}
