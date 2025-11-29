import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/xboard/features/invite/providers/invite_provider.dart';
import 'package:fl_clash/xboard/config/xboard_config.dart';
import 'package:fl_clash/xboard/features/invite/widgets/qr_code_widget.dart';
import 'package:fl_clash/xboard/utils/xboard_notification.dart';

class InviteQrCard extends ConsumerWidget {
  const InviteQrCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(inviteProvider);
    
    final firstCode = inviteState.hasInviteData && inviteState.inviteData!.codes.isNotEmpty
        ? inviteState.inviteData!.codes.first
        : null;
    
    // 使用 buildRegisterUrl 基于邀请码哈希选择URL
    final inviteUrl = firstCode != null 
        ? _buildInviteUrl(firstCode.code)
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              appLocalizations.myInviteQr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            if (firstCode != null) ...[
              QrCodeWidget(
                data: inviteUrl,
                size: 200,
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _saveQrCode(context, inviteUrl),
                    icon: const Icon(Icons.save_alt),
                    label: Text(appLocalizations.saveQr),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(context, inviteUrl),
                    icon: const Icon(Icons.link),
                    label: Text(appLocalizations.copyInviteLink),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ] else if (inviteState.isLoading || inviteState.isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.generatingInviteCode,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLocalizations.noInviteCodeYet,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _generateInviteCode(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(appLocalizations.generateInviteCode),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    XBoardNotification.showSuccess(appLocalizations.copiedToClipboard);
  }

  void _saveQrCode(BuildContext context, String inviteUrl) {
    XBoardNotification.showInfo(appLocalizations.saveQrCodeFeature);
  }

  Future<void> _generateInviteCode(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(inviteProvider.notifier).generateInviteCode();
    if (result != null) {
      XBoardNotification.showSuccess(appLocalizations.inviteCodeGeneratedSuccessfully);
    } else {
      XBoardNotification.showError(appLocalizations.inviteCodeGenFailed);
    }
  }

  String _buildInviteUrl(String inviteCode) {
    try {
      // 使用 buildRegisterUrl 方法，基于邀请码哈希选择不同URL
      return XBoardConfig.buildRegisterUrl(inviteCode) ?? '';
    } catch (e) {
      return '';
    }
  }
}