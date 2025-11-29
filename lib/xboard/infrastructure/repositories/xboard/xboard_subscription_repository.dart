import 'package:fl_clash/xboard/core/core.dart';
import 'package:fl_clash/xboard/domain/domain.dart';
import 'package:fl_clash/xboard/sdk/xboard_sdk.dart' as sdk;
import 'package:flutter_xboard_sdk/flutter_xboard_sdk.dart' as xb_sdk;

/// XBoard 订阅仓储实现
class XBoardSubscriptionRepository implements SubscriptionRepository {
  final _logger = FileLogger('XBoardSubscriptionRepository');

  @override
  Future<Result<DomainSubscription>> getSubscription() async {
    try {
      _logger.info('获取订阅信息...');
      
      final subscription = await sdk.XBoardSDK.getSubscription();
      
      if (subscription == null) {
        return Result.failure(
          XBoardException(
            code: 'SUBSCRIPTION_NULL',
            message: '订阅信息为空',
          ),
        );
      }
      
      final domainSubscription = _mapToDomain(subscription);
      
      _logger.info('订阅信息获取成功');
      return Result.success(domainSubscription);
      
    } on XBoardException catch (e) {
      _logger.info('获取订阅信息失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('获取订阅信息异常: $e');
      return Result.failure(
        XBoardException(
          code: 'GET_SUBSCRIPTION_ERROR',
          message: '获取订阅信息失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<String>> getSubscriptionUrl() async {
    try {
      _logger.info('获取订阅链接...');
      
      final subscription = await sdk.XBoardSDK.getSubscription();
      
      if (subscription?.subscribeUrl == null) {
        return Result.failure(
          XBoardException(
            code: 'SUBSCRIPTION_URL_NULL',
            message: '订阅链接为空',
          ),
        );
      }
      
      _logger.info('订阅链接获取成功');
      return Result.success(subscription!.subscribeUrl!);
      
    } on XBoardException catch (e) {
      _logger.info('获取订阅链接失败: ${e.message}');
      return Result.failure(e);
    } catch (e) {
      _logger.info('获取订阅链接异常: $e');
      return Result.failure(
        XBoardException(
          code: 'GET_SUBSCRIPTION_URL_ERROR',
          message: '获取订阅链接失败: $e',
        ),
      );
    }
  }

  @override
  Future<Result<String>> resetSubscriptionUrl() async {
    try {
      _logger.info('重置订阅链接...');
      
      // TODO: SDK 暂未实现此功能
      _logger.info('警告: 重置订阅链接功能暂未实现');
      return Result.failure(
        XBoardException(
          code: 'NOT_IMPLEMENTED',
          message: '重置订阅链接功能暂未实现',
        ),
      );
      
    } catch (e) {
      _logger.info('重置订阅链接异常: $e');
      return Result.failure(
        XBoardException(
          code: 'RESET_SUBSCRIPTION_URL_ERROR',
          message: '重置订阅链接失败: $e',
        ),
      );
    }
  }

  // ========== 私有方法：数据转换 ==========

  DomainSubscription _mapToDomain(xb_sdk.SubscriptionInfo sdkSub) {
    _logger.info('[_mapToDomain] SDK subscribeUrl: ${sdkSub.subscribeUrl}');
    _logger.info('[_mapToDomain] SDK transferEnable: ${sdkSub.transferEnable}');
    _logger.info('[_mapToDomain] SDK u: ${sdkSub.u}, d: ${sdkSub.d}');
    _logger.info('[_mapToDomain] SDK expiredAt: ${sdkSub.expiredAt}');
    
    return DomainSubscription(
      subscribeUrl: sdkSub.subscribeUrl ?? '',
      email: sdkSub.email ?? '',
      uuid: sdkSub.uuid ?? '',
      planId: sdkSub.planId ?? 0,
      planName: sdkSub.plan?.name,
      token: sdkSub.token,
      transferLimit: sdkSub.transferEnable ?? 0,
      uploadedBytes: sdkSub.u ?? 0,
      downloadedBytes: sdkSub.d ?? 0,
      speedLimit: sdkSub.speedLimit,
      deviceLimit: sdkSub.deviceLimit,
      expiredAt: sdkSub.expiredAt,
      nextResetAt: sdkSub.nextResetAt,
      metadata: {
        'source': 'xboard',
      },
    );
  }
}
