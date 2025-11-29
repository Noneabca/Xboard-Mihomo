import 'config_entry.dart';

/// 注册页面URL信息
/// 
/// 用于邀请链接的前端注册页面域名配置
class RegisterUrlInfo extends ConfigEntry {
  const RegisterUrlInfo({
    required super.url,
    required super.description,
  });

  /// 从JSON创建注册URL信息
  factory RegisterUrlInfo.fromJson(Map<String, dynamic> json) {
    return RegisterUrlInfo(
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// 构建完整的注册链接
  /// 
  /// [inviteCode] 邀请码
  String buildRegisterUrl(String inviteCode) {
    // 移除末尾的斜杠
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$baseUrl/#/register?code=$inviteCode';
  }

  @override
  String toString() {
    return 'RegisterUrlInfo(url: $url, description: $description)';
  }
}

/// 注册页面配置信息
class RegisterInfo {
  final List<RegisterUrlInfo> urls;

  const RegisterInfo({
    required this.urls,
  });

  /// 从JSON创建注册配置
  factory RegisterInfo.fromJson(Map<String, dynamic> json) {
    final urlsList = json['urls'] as List<dynamic>? ?? [];
    
    return RegisterInfo(
      urls: urlsList
          .map((item) => RegisterUrlInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 获取第一个可用的注册URL
  String? get firstUrl {
    return urls.isNotEmpty ? urls.first.url : null;
  }

  /// 构建注册链接（基于邀请码哈希选择URL）
  /// 
  /// [inviteCode] 邀请码
  /// 
  /// 同一个邀请码始终对应同一个URL，不同邀请码分散到不同URL
  String? buildRegisterUrl(String inviteCode) {
    if (urls.isEmpty) return null;
    
    // 使用邀请码的哈希值来选择URL，确保同一个邀请码始终对应同一个URL
    final hash = inviteCode.hashCode.abs();
    final index = hash % urls.length;
    return urls[index].buildRegisterUrl(inviteCode);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'urls': urls.map((url) => url.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'RegisterInfo(urls: ${urls.length})';
  }
}
