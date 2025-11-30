import 'package:fl_clash/xboard/core/core.dart';
import 'package:fl_clash/xboard/domain/domain.dart';
import 'package:fl_clash/xboard/sdk/xboard_sdk.dart' as sdk;
import 'package:flutter_xboard_sdk/flutter_xboard_sdk.dart' as xb_sdk;

/// XBoard 邀请仓储实现
class XBoardInviteRepository implements InviteRepository {
  final _logger = FileLogger('XBoardInviteRepository');

  @override
  Future<Result<DomainInvite>> getInviteInfo() async {
    try {
      _logger.info('获取邀请信息...');
      
      final inviteInfo = await sdk.XBoardSDK.getInviteInfo();
      
      if (inviteInfo == null) {
        return Result.failure(
          XBoardException(
            code: 'INVITE_INFO_NOT_FOUND',
            message: '邀请信息不存在',
          ),
        );
      }
      
      final domainInvite = _mapToDomain(inviteInfo);
      
      _logger.info('邀请信息获取成功');
      return Result.success(domainInvite);
      
    } on XBoardException catch (e) {
      _logger.info('获取邀请信息失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('获取邀请信息异常: $e');
      return Result.failure(
        XBoardException(
          code: 'GET_INVITE_INFO_ERROR',
          message: '获取邀请信息失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<DomainInviteCode>> generateInviteCode() async {
    try {
      _logger.info('生成邀请码...');
      
      final inviteCode = await sdk.XBoardSDK.generateInviteCode();
      
      if (inviteCode == null) {
        return Result.failure(
          XBoardException(
            code: 'GENERATE_CODE_FAILED',
            message: '生成邀请码失败',
          ),
        );
      }
      
      final domainCode = DomainInviteCode(
        code: inviteCode.code,
        status: inviteCode.status ? 1 : 0,
        createdAt: inviteCode.createdAt,
      );
      
      _logger.info('邀请码生成成功: ${inviteCode.code}');
      return Result.success(domainCode);
      
    } on XBoardException catch (e) {
      _logger.info('生成邀请码失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('生成邀请码异常: $e');
      return Result.failure(
        XBoardException(
          code: 'GENERATE_INVITE_CODE_ERROR',
          message: '生成邀请码失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<DomainCommission>>> getCommissionHistory({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      _logger.info('获取佣金历史...');
      
      final history = await sdk.XBoardSDK.getCommissionHistory();
      
      final domainHistory = history.map(_mapCommissionToDomain).toList();
      
      _logger.info('佣金历史获取成功，共 ${domainHistory.length} 条');
      return Result.success(domainHistory);
      
    } on XBoardException catch (e) {
      _logger.info('获取佣金历史失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('获取佣金历史异常: $e');
      return Result.failure(
        XBoardException(
          code: 'GET_COMMISSION_HISTORY_ERROR',
          message: '获取佣金历史失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> transferCommissionToBalance(double amountInYuan) async {
    try {
      _logger.info('划转佣金: ${amountInYuan}元');
      
      await sdk.XBoardSDK.transferCommissionToBalance(amountInYuan);
      
      _logger.info('佣金划转成功');
      return Result.success(null);
      
    } on XBoardException catch (e) {
      _logger.info('佣金划转失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('佣金划转异常: $e');
      return Result.failure(
        XBoardException(
          code: 'TRANSFER_COMMISSION_ERROR',
          message: '佣金划转失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> withdrawCommission({
    required String method,
    required String account,
  }) async {
    try {
      _logger.info('提现佣金: method=$method');
      
      // 通过 SDK 调用提现接口（V2Board 通过工单系统）
      await sdk.XBoardSDK.withdrawCommission(
        withdrawMethod: method,
        withdrawAccount: account,
      );
      
      _logger.info('提现申请提交成功');
      return Result.success(null);
      
    } on XBoardException catch (e) {
      _logger.info('提现佣金失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('提现佣金异常: $e');
      return Result.failure(
        XBoardException(
          code: 'WITHDRAW_COMMISSION_ERROR',
          message: '提现佣金失败: $e',
        ),
      );
    }
  }

  // ========== 私有方法：数据转换 ==========

  DomainInvite _mapToDomain(xb_sdk.InviteInfo sdkInvite) {
    final codes = (sdkInvite.codes).map((code) {
      return DomainInviteCode(
        code: code.code,
        status: code.status ? 1 : 0,  // bool → int
        createdAt: code.createdAt,  // 已经是 DateTime
      );
    }).toList();

    // stat 是 List<int>，通过 getter 访问
    final stats = InviteStats(
      invitedCount: sdkInvite.totalInvites,
      commissionRate: sdkInvite.commissionRate.toDouble(),  // 已经是百分比值，不需要除以100
      pendingCommission: (sdkInvite.pendingCommission) / 100.0,  // 分 → 元
      availableCommission: (sdkInvite.availableCommission) / 100.0,  // 分 → 元
      totalCommission: (sdkInvite.totalCommission) / 100.0,  // 分 → 元
    );

    return DomainInvite(
      codes: codes,
      stats: stats,
    );
  }

  DomainCommission _mapCommissionToDomain(xb_sdk.CommissionDetail detail) {
    return DomainCommission(
      id: detail.id,
      tradeNo: detail.tradeNo,
      amount: detail.getAmountInYuan,
      createdAt: detail.createdAt,
    );
  }
}
