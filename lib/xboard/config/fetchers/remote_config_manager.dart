import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/config_settings.dart';
import '../../core/core.dart';

// 初始化文件级日志器
final _logger = FileLogger('remote_config_manager.dart');

/// 远程配置状态枚举
enum RemoteConfigStatus {
  uninitialized,
  loading,
  success,
  error,
}

/// 配置获取结果
class ConfigResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String source;
  final RemoteConfigStatus status;
  final DateTime fetchTime;

  const ConfigResult({
    required this.isSuccess,
    this.data,
    this.error,
    required this.source,
    required this.status,
    required this.fetchTime,
  });

  factory ConfigResult.success(T data, String source) {
    return ConfigResult(
      isSuccess: true,
      data: data,
      source: source,
      status: RemoteConfigStatus.success,
      fetchTime: DateTime.now(),
    );
  }

  factory ConfigResult.failure(String error, String source) {
    return ConfigResult(
      isSuccess: false,
      error: error,
      source: source,
      status: RemoteConfigStatus.error,
      fetchTime: DateTime.now(),
    );
  }
}

/// 多配置源结果
class MultiConfigResult {
  /// 所有配置源结果（按优先级排序）
  final List<ConfigResult<Map<String, dynamic>>> results;
  
  const MultiConfigResult(this.results);
  
  /// 兼容旧接口：重定向配置源结果
  ConfigResult<Map<String, dynamic>> get redirectResult {
    return results.firstWhere(
      (r) => r.source == 'redirect',
      orElse: () => ConfigResult.failure('重定向配置源未注册', 'redirect'),
    );
  }
  
  /// 兼容旧接口：Gitee配置源结果
  ConfigResult<Map<String, dynamic>> get giteeResult {
    return results.firstWhere(
      (r) => r.source == 'gitee',
      orElse: () => ConfigResult.failure('Gitee配置源未注册', 'gitee'),
    );
  }
  
  /// 是否有任何一个配置源成功
  bool get hasSuccess => results.any((r) => r.isSuccess);
  
  /// 获取第一个成功的配置数据
  Map<String, dynamic>? get firstSuccessfulData {
    final successResult = results.firstWhere(
      (r) => r.isSuccess && r.data != null,
      orElse: () => ConfigResult.failure('无成功配置', 'none'),
    );
    return successResult.data;
  }
  
  /// 获取第一个成功的配置源名称
  String? get firstSuccessfulSource {
    final successResult = results.firstWhere(
      (r) => r.isSuccess,
      orElse: () => ConfigResult.failure('无成功配置', 'none'),
    );
    return successResult.isSuccess ? successResult.source : null;
  }

  /// 获取第一个成功的结果
  ConfigResult<Map<String, dynamic>>? get firstSuccessful {
    try {
      return results.firstWhere((r) => r.isSuccess);
    } catch (e) {
      return null;
    }
  }
  
  @override
  String toString() {
    final statusMap = {for (var r in results) r.source: r.status};
    return 'MultiConfigResult{$statusMap}';
  }
}

/// HTTP客户端抽象接口
abstract class IHttpClient {
  Future<String?> getString(String url, {Duration? timeout});
}

/// 简单的HTTP客户端实现
class SimpleHttpClient implements IHttpClient {
  @override
  Future<String?> getString(String url, {Duration? timeout}) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = timeout ?? const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }

      return null;
    } catch (e) {
      return null;
    } finally {
      client?.close();
    }
  }
}

/// 配置源抽象接口
abstract class ConfigSource {
  String get sourceName;
  int get priority;
  Future<ConfigResult<Map<String, dynamic>>> fetchConfig();
}

/// 重定向配置源实现
class RedirectConfigSource implements ConfigSource {
  final IHttpClient _httpClient;
  final String redirectUrl;
  final Duration timeout;

  RedirectConfigSource({
    IHttpClient? httpClient,
    required this.redirectUrl,
    Duration? timeout,
  }) : _httpClient = httpClient ?? SimpleHttpClient(),
       timeout = timeout ?? const Duration(seconds: 10);

  @override
  String get sourceName => 'redirect';

  @override
  int get priority => 1;

  @override
  Future<ConfigResult<Map<String, dynamic>>> fetchConfig() async {
    try {
      _logger.info('开始获取重定向配置源: $redirectUrl');
      final rawData = await _httpClient.getString(redirectUrl, timeout: timeout);

      if (rawData == null || rawData.trim().isEmpty) {
        _logger.error('重定向配置源获取失败: 数据为空');
        return ConfigResult.failure("重定向配置源获取失败", sourceName);
      }

      final jsonData = json.decode(rawData.trim()) as Map<String, dynamic>;
      _logger.info('重定向配置源获取成功');
      return ConfigResult.success(jsonData, sourceName);

    } catch (e) {
      _logger.error('重定向配置源异常', e);
      return ConfigResult.failure("重定向配置源异常: ${e.toString()}", sourceName);
    }
  }
}

/// Gitee配置源实现
class GiteeConfigSource implements ConfigSource {
  final IHttpClient _httpClient;
  final String giteeUrl;
  final String encryptionKeyBase64;
  final Duration timeout;

  GiteeConfigSource({
    IHttpClient? httpClient,
    required this.giteeUrl,
    required this.encryptionKeyBase64,
    Duration? timeout,
  }) : _httpClient = httpClient ?? SimpleHttpClient(),
       timeout = timeout ?? const Duration(seconds: 10);

  @override
  String get sourceName => 'gitee';

  @override
  int get priority => 2;

  @override
  Future<ConfigResult<Map<String, dynamic>>> fetchConfig() async {
    try {
      final encryptedData = await _httpClient.getString(giteeUrl, timeout: timeout);

      if (encryptedData == null) {
        return ConfigResult.failure("Gitee配置源获取失败", sourceName);
      }

      final decryptedConfig = await _decryptConfigData(encryptedData.trim());

      if (decryptedConfig == null) {
        return ConfigResult.failure("Gitee配置源解密失败", sourceName);
      }

      return ConfigResult.success(decryptedConfig, sourceName);

    } catch (e) {
      return ConfigResult.failure("Gitee配置源异常: ${e.toString()}", sourceName);
    }
  }

  /// 解密配置数据（AES-GCM解密）
  Future<Map<String, dynamic>?> _decryptConfigData(String encryptedBase64) async {
    try {
      final encryptedBytes = base64.decode(encryptedBase64);
      final keyBytes = base64.decode(encryptionKeyBase64);

      const nonceLength = 16;
      const tagLength = 16;

      if (encryptedBytes.length < nonceLength + tagLength) {
        throw Exception('加密数据长度不足: ${encryptedBytes.length}');
      }

      final nonce = encryptedBytes.sublist(0, nonceLength);
      final ciphertext = encryptedBytes.sublist(
          nonceLength, encryptedBytes.length - tagLength);
      final tag = encryptedBytes.sublist(encryptedBytes.length - tagLength);

      final key = Key(keyBytes);
      final iv = IV(nonce);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      final encrypted = Encrypted(Uint8List.fromList(ciphertext + tag));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      final jsonData = json.decode(decrypted) as Map<String, dynamic>;
      return jsonData;
    } catch (e) {
      return null;
    }
  }
}

/// 本地 Assets 配置源实现
class LocalConfigSource implements ConfigSource {
  final String assetPath;
  final Duration timeout;

  LocalConfigSource({
    required this.assetPath,
    Duration? timeout,
  }) : timeout = timeout ?? const Duration(seconds: 5);

  @override
  String get sourceName => 'local';

  @override
  int get priority => 0; // 最高优先级

  @override
  Future<ConfigResult<Map<String, dynamic>>> fetchConfig() async {
    try {
      _logger.info('开始从 Assets 加载本地配置: $assetPath');
      
      // 从 assets 加载配置文件
      final jsonString = await rootBundle.loadString(assetPath);
      
      if (jsonString.trim().isEmpty) {
        _logger.error('本地配置文件为空');
        return ConfigResult.failure("本地配置文件为空", sourceName);
      }

      final jsonData = json.decode(jsonString.trim()) as Map<String, dynamic>;
      _logger.info('本地配置加载成功');
      return ConfigResult.success(jsonData, sourceName);

    } catch (e) {
      _logger.error('本地配置加载异常', e);
      return ConfigResult.failure("本地配置加载异常: ${e.toString()}", sourceName);
    }
  }
}

/// 远程配置源（兼容旧接口）
class RemoteConfigSource {
  final String name;
  final String url;
  final Map<String, String>? headers;
  final Duration timeout;

  const RemoteConfigSource({
    required this.name,
    required this.url,
    this.headers,
    this.timeout = const Duration(seconds: 10),
  });

  /// 从配置源获取数据
  Future<ConfigResult<Map<String, dynamic>>> fetch() async {
    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = timeout;

      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      
      // 添加请求头
      if (headers != null) {
        headers!.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody) as Map<String, dynamic>;
        
        client.close();
        return ConfigResult.success(data, name);
      } else {
        client.close();
        return ConfigResult.failure(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          name,
        );
      }
    } catch (e) {
      return ConfigResult.failure('Network error: $e', name);
    }
  }
}

/// 远程配置管理器
class RemoteConfigManager {
  final List<ConfigSource> _configSources;
  final int _maxRetries;
  final Duration _retryDelay;
  final bool _enableConcurrentFetch;

  RemoteConfigManager({
    List<ConfigSource>? sources,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool enableConcurrentFetch = true,
  }) : _configSources = sources ?? _createDefaultSources(),
       _maxRetries = maxRetries,
       _retryDelay = retryDelay,
       _enableConcurrentFetch = enableConcurrentFetch;

  /// 从配置设置创建RemoteConfigManager
  factory RemoteConfigManager.fromSettings(RemoteConfigSettings settings) {
    final sources = <ConfigSource>[];
    
    for (final sourceConfig in settings.sources) {
      switch (sourceConfig.name) {
        case 'local':
          // 本地 assets 配置源
          sources.add(LocalConfigSource(
            assetPath: sourceConfig.url,
            timeout: sourceConfig.timeout ?? settings.timeout,
          ));
          _logger.info('[ConfigManager] 添加本地配置源: ${sourceConfig.url}');
          break;
        case 'redirect':
          sources.add(RedirectConfigSource(
            redirectUrl: sourceConfig.url,
            timeout: sourceConfig.timeout ?? settings.timeout,
          ));
          break;
        case 'gitee':
          if (sourceConfig.encryptionKey == null || sourceConfig.encryptionKey!.isEmpty) {
            throw Exception('Gitee配置源必须提供 encryptionKey');
          }
          sources.add(GiteeConfigSource(
            giteeUrl: sourceConfig.url,
            encryptionKeyBase64: sourceConfig.encryptionKey!,
            timeout: sourceConfig.timeout ?? settings.timeout,
          ));
          break;
      }
    }
    
    return RemoteConfigManager(
      sources: sources,
      maxRetries: settings.maxRetries,
      retryDelay: settings.retryDelay,
    );
  }

  /// 创建默认配置源（空列表，必须从配置文件提供）
  static List<ConfigSource> _createDefaultSources() {
    return [];
  }

  /// 从所有配置源获取配置
  Future<MultiConfigResult> fetchAllConfigs() async {
    if (_configSources.isEmpty) {
      throw Exception('没有可用的配置源');
    }

    // 按优先级排序配置源（优先级低的先执行）
    final sortedSources = List<ConfigSource>.from(_configSources)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    List<ConfigResult<Map<String, dynamic>>> results;

    if (_enableConcurrentFetch && sortedSources.length > 1) {
      // 并发请求
      _logger.info('[配置管理器] 并发获取 ${sortedSources.length} 个配置源');
      results = await Future.wait(
        sortedSources.map((source) => _fetchWithRetry(source)),
      );
    } else {
      // 串行请求
      _logger.info('[配置管理器] 串行获取 ${sortedSources.length} 个配置源');
      results = [];
      for (final source in sortedSources) {
        final result = await _fetchWithRetry(source);
        results.add(result);
        
        // 如果有一个成功，且优先级最高，可以提前返回
        if (result.isSuccess && source.priority == 0) {
          _logger.info('[配置管理器] 最高优先级配置源 ${source.sourceName} 成功，提前返回');
          break;
        }
      }
    }

    return MultiConfigResult(results);
  }

  /// 只获取重定向配置源的结果
  Future<ConfigResult<Map<String, dynamic>>> getRedirectConfig() async {
    final redirectSource = _configSources.firstWhere(
      (source) => source.sourceName == 'redirect',
      orElse: () => throw Exception('重定向配置源未注册'),
    );
    return await _fetchWithRetry(redirectSource);
  }

  /// 只获取Gitee配置源的结果
  Future<ConfigResult<Map<String, dynamic>>> getGiteeConfig() async {
    final giteeSource = _configSources.firstWhere(
      (source) => source.sourceName == 'gitee',
      orElse: () => throw Exception('Gitee配置源未注册'),
    );
    return await _fetchWithRetry(giteeSource);
  }

  /// 从指定配置源获取配置
  Future<ConfigResult<Map<String, dynamic>>> fetchFromSource(String sourceName) async {
    final source = _configSources.firstWhere(
      (s) => s.sourceName == sourceName,
      orElse: () => throw ArgumentError('Unknown source: $sourceName'),
    );
    
    return await _fetchWithRetry(source);
  }

  /// 获取第一个可用的配置
  Future<ConfigResult<Map<String, dynamic>>> fetchConfig() async {
    final multiResult = await fetchAllConfigs();
    
    if (multiResult.hasSuccess) {
      return multiResult.firstSuccessful!;
    } else {
      return ConfigResult.failure(
        'All config sources failed',
        'all',
      );
    }
  }

  /// 带重试的获取
  Future<ConfigResult<Map<String, dynamic>>> _fetchWithRetry(ConfigSource source) async {
    ConfigResult<Map<String, dynamic>>? lastResult;
    
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      lastResult = await source.fetchConfig();
      
      if (lastResult.isSuccess) {
        return lastResult;
      }
      
      // 如果不是最后一次尝试，等待后重试
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }
    
    return lastResult!;
  }

  /// 添加配置源
  void addSource(ConfigSource source) {
    _configSources.add(source);
  }

  /// 移除配置源
  void removeSource(String sourceName) {
    _configSources.removeWhere((source) => source.sourceName == sourceName);
  }

  /// 获取所有配置源名称
  List<String> get sourceNames => _configSources.map((s) => s.sourceName).toList();

  /// 获取配置源数量
  int get sourceCount => _configSources.length;
}