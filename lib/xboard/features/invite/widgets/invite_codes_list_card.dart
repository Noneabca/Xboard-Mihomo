import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/xboard/features/invite/providers/invite_provider.dart';
import 'package:fl_clash/xboard/config/xboard_config.dart';
import 'package:fl_clash/xboard/utils/xboard_notification.dart';
import 'package:fl_clash/xboard/domain/models/invite.dart';
import 'package:intl/intl.dart';

/// 邀请码列表卡片
class InviteCodesListCard extends ConsumerWidget {
  const InviteCodesListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(inviteProvider);
    final codes = inviteState.inviteData?.codes ?? [];

    if (codes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appLocalizations.inviteCodeList,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _generateNewCode(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(appLocalizations.generateInviteCode),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: codes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final code = codes[index];
                // 使用 buildRegisterUrl 基于邀请码哈希选择不同URL
                final inviteUrl = _buildInviteUrl(code.code);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: SelectableText(
                    code.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: code.createdAt != null
                      ? Text(
                          '${appLocalizations.created}: ${_formatDate(code.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyInviteCode(context, code.code),
                        tooltip: appLocalizations.copyInviteCode,
                      ),
                      if (inviteUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.link, size: 18),
                          onPressed: () => _copyInviteLink(context, inviteUrl),
                          tooltip: appLocalizations.copyInviteLink,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return DateFormat('yyyy-MM-dd').format(date);
    } else if (difference.inDays > 0) {
      return DateFormat('MM-dd HH:mm').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${appLocalizations.hours}${appLocalizations.ago}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${appLocalizations.minutes}${appLocalizations.ago}';
    } else {
      return appLocalizations.just;
    }
  }

  void _copyInviteCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    XBoardNotification.showSuccess(appLocalizations.inviteCodeCopied);
  }

  void _copyInviteLink(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    XBoardNotification.showSuccess(appLocalizations.inviteLinkCopied);
  }

  Future<void> _generateNewCode(BuildContext context, WidgetRef ref) async {
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
