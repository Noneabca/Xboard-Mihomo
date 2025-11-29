import 'package:fl_clash/xboard/core/core.dart';
import 'package:fl_clash/xboard/domain/domain.dart';
import 'package:fl_clash/xboard/sdk/xboard_sdk.dart' as sdk;
import 'package:flutter_xboard_sdk/flutter_xboard_sdk.dart' as xb_sdk;

/// XBoard 用户仓储实现
/// 
/// 负责将 XBoard SDK 的数据适配到领域层
class XBoardUserRepository implements UserRepository {
  final _logger = FileLogger('XBoardUserRepository');

  @override
  Future<Result<DomainUser>> getUserInfo() async {
    try {
      _logger.info('获取用户信息...');
      
      // 调用 SDK 获取用户信息
      final userInfo = await sdk.XBoardSDK.getUserInfo();
      
      if (userInfo == null) {
        return Result.failure(
          XBoardException(
            code: 'USER_INFO_NULL',
            message: '用户信息为空',
          ),
        );
      }

      // 获取订阅信息（用于补充流量数据）
      final subscription = await sdk.XBoardSDK.getSubscription();
      
      // 转换为领域模型
      final domainUser = _mapToDomain(userInfo, subscription);
      
      _logger.info('用户信息获取成功: ${domainUser.email}');
      return Result.success(domainUser);
      
    } on XBoardException catch (e) {
      _logger.info('获取用户信息失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('获取用户信息异常: $e');
      return Result.failure(
        XBoardException(
          code: 'USER_INFO_ERROR',
          message: '获取用户信息失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<bool>> validateToken() async {
    try {
      _logger.info('验证 Token...');
      
      final isValid = await sdk.XBoardSDK.validateToken();
      
      _logger.info('Token 验证结果: $isValid');
      return Result.success(isValid);
      
    } on XBoardException catch (e) {
      _logger.info('Token 验证失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('Token 验证异常: $e');
      return Result.failure(
        XBoardException(
          code: 'TOKEN_VALIDATION_ERROR',
          message: 'Token 验证失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> toggleTrafficReminder(bool enabled) async {
    try {
      _logger.info('切换流量提醒: $enabled');
      
      await sdk.XBoardSDK.toggleTrafficReminder(enabled);
      
      _logger.info('流量提醒更新成功');
      return Result.success(null);
      
    } on XBoardException catch (e) {
      _logger.info('更新流量提醒失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('更新流量提醒异常: $e');
      return Result.failure(
        XBoardException(
          code: 'UPDATE_REMINDER_ERROR',
          message: '更新流量提醒失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> toggleExpireReminder(bool enabled) async {
    try {
      _logger.info('切换到期提醒: $enabled');
      
      await sdk.XBoardSDK.toggleExpireReminder(enabled);
      
      _logger.info('到期提醒更新成功');
      return Result.success(null);
      
    } on XBoardException catch (e) {
      _logger.info('更新到期提醒失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('更新到期提醒异常: $e');
      return Result.failure(
        XBoardException(
          code: 'UPDATE_REMINDER_ERROR',
          message: '更新到期提醒失败: $e',
        ),
      );
    }
  }

  // ========== 私有方法：数据转换 ==========

  /// 将 SDK 模型转换为领域模型
  DomainUser _mapToDomain(
    xb_sdk.UserInfo sdkUser,
    xb_sdk.SubscriptionInfo? subscription,
  ) {
    return DomainUser(
      email: sdkUser.email,
      uuid: sdkUser.uuid,
      avatarUrl: sdkUser.avatarUrl ?? '', // 默认空字符串如果为null
      planId: sdkUser.planId,
      
      // 流量信息（优先从订阅信息获取，因为更准确）
      transferLimit: subscription?.transferEnable ?? sdkUser.transferEnable.toInt(),
      uploadedBytes: subscription?.u ?? 0,
      downloadedBytes: subscription?.d ?? 0,
      
      // 余额信息（单位：分）
      balanceInCents: sdkUser.balance.toInt(),
      commissionBalanceInCents: sdkUser.commissionBalance.toInt(),
      
      // 时间信息
      expiredAt: sdkUser.expiredAt,
      lastLoginAt: sdkUser.lastLoginAt,
      createdAt: sdkUser.createdAt,
      
      // 状态信息
      banned: sdkUser.banned,
      remindExpire: sdkUser.remindExpire,
      remindTraffic: sdkUser.remindTraffic,
      
      // 其他信息
      discount: sdkUser.discount,
      commissionRate: sdkUser.commissionRate,
      telegramId: sdkUser.telegramId,
      
      // 元数据（存储 SDK 特有字段）
      metadata: {
        'source': 'xboard',
        'sdk_version': '1.0',
      },
    );
  }
}
