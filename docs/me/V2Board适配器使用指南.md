# V2Board 适配器使用指南

## ✨ 功能介绍

V2Board 适配器是一个 HTTP 响应拦截器,可以自动转换 V2Board 和 XBoard 之间的 API 数据格式差异,让您无需修改任何业务代码即可使用 V2Board 后端。

## 📋 API 差异说明

根据 `本项目与v2board的api差异.md` 分析,主要差异如下:

### 1. 订阅信息响应差异 ⚠️ (重要)

**V2Board** 返回:
```json
{
  "reset_day": 15,        // 流量重置日
  "alive_ip": 2,          // 在线设备数
  "allow_new_period": 0   // 是否允许新周期
}
```

**XBoard 项目期望**:
```json
{
  "next_reset_at": 1704067200,  // 下次重置时间戳
  "email": "user@example.com",
  "uuid": "xxx-xxx-xxx",
  "speed_limit": null
}
```

**适配器处理**:
- ✅ `reset_day` → `next_reset_at` (自动计算下次重置时间)
- ✅ 补充缺失字段: `email`, `uuid`, `speed_limit`
- ✅ 移除多余字段: `alive_ip`, `allow_new_period`

### 2. 用户信息响应差异

**V2Board** 多返回:
- `device_limit` (设备限制)
- `auto_renewal` (自动续费)

**适配器处理**:
- ✅ 自动移除项目不需要的字段

### 3. 登录响应差异

**V2Board** 多返回:
- `is_admin`
- `is_staff`

**适配器处理**:
- ✅ 自动移除多余字段

### 4. 订单周期类型差异

**V2Board** 支持更多周期:
- `two_year_price` (两年付)
- `three_year_price` (三年付)
- `onetime_price` (一次性)

**适配器处理**:
- ⚠️ 记录日志提示不支持的周期类型
- 前端可能无法展示这些选项

## 🚀 启用方法

### 步骤 1: 修改配置文件

编辑 `assets/config/xboard.config.yaml`:

```yaml
xboard:
  provider: mihomo
  
  # ... 其他配置 ...
  
  security:
    # ✨ 启用 V2Board 适配器
    enable_v2board_adapter: true  # 改为 true
    
    # ... 其他安全配置 ...
```

### 步骤 2: 重启应用

配置修改后需要重启应用才能生效。

## 📝 配置示例

### V2Board 完整配置示例

```yaml
xboard:
  provider: mihomo
  
  remote_config:
    sources:
      - name: redirect
        url: https://your-v2board-domain.com/config.json
        priority: 100
  
  app:
    title: V2Board客户端
    website: v2board.example.com
  
  subscription:
    prefer_encrypt: false
    decrypt_key: your_decrypt_key_here
  
  security:
    # 重要: 启用 V2Board 适配器
    enable_v2board_adapter: true
    
    # 如果使用混淆,配置混淆前缀
    obfuscation_prefix: YOUR_OBFS_PREFIX_
    
    user_agents:
      api_encrypted: Mozilla/5.0 (compatible; YOUR_ENCRYPTED_STRING_HERE)
      domain_racing_test: FlClash/1.0 (Domain Racing Test)
```

## 🔍 工作原理

```
应用请求 → V2Board API
              ↓
          响应返回
              ↓
    [V2Board 适配拦截器]  ← 在这里自动转换
              ↓
          标准格式数据
              ↓
        业务层处理
```

### 拦截器执行顺序

```
HTTP 请求
  ↓
[V2Board 适配器]    ← 第一优先级
  ↓
[响应解混淆]
  ↓
[响应格式化]
  ↓
[认证拦截器]
  ↓
业务层
```

## 🎯 优势

### ✅ 零侵入

- 不修改任何业务代码
- 不修改数据模型
- 不影响 XBoard 原有功能

### ✅ 集中管理

所有适配逻辑在一个文件中:
```
lib/sdk/flutter_xboard_sdk/lib/src/core/http/v2board_adapter.dart
```

### ✅ 易于维护

- 可随时启用/禁用
- 不影响跟随上游更新
- 适配失败不影响原始响应

### ✅ 可配置化

通过配置文件控制:
```yaml
enable_v2board_adapter: true/false
```

## 📊 适配详情

### 订阅信息适配

**适配前** (V2Board 返回):
```json
{
  "data": {
    "subscribe_url": "...",
    "reset_day": 15,
    "alive_ip": 2,
    "transfer_enable": 107374182400
  }
}
```

**适配后** (项目接收):
```json
{
  "data": {
    "subscribe_url": "...",
    "next_reset_at": 1704067200,  // 自动计算
    "email": null,                 // 自动补充
    "uuid": null,                  // 自动补充
    "speed_limit": null,           // 自动补充
    "transfer_enable": 107374182400
  }
}
```

## ⚠️ 注意事项

### 1. reset_day 计算逻辑

适配器会根据当前日期计算 `next_reset_at`:
- 如果 `reset_day` 已过 → 计算下个月的重置日
- 如果 `reset_day` 未到 → 使用本月的重置日

### 2. 缺失字段处理

部分字段可能为 `null`,业务层需要处理空值情况:
- `email` - 可能为 null
- `uuid` - 可能为 null
- `speed_limit` - 可能为 null

### 3. 不支持的周期类型

如果 V2Board 配置了两年付、三年付等,前端可能无法展示,会在日志中提示:
```
[V2BoardAdapter] Warning: Unsupported period type: two_year_price
```

## 🛠️ 故障排查

### 适配器未生效?

1. 检查配置文件:
```bash
# 确认配置正确
grep "enable_v2board_adapter" assets/config/xboard.config.yaml
```

2. 查看日志:
```
[ConfigLoader] V2Board适配器: 已启用
[XBoardSDK] ✅ V2Board 适配器已启用
```

3. 确认重启应用

### 数据显示异常?

1. 检查适配日志:
```
[V2BoardAdapter] Converted reset_day (15) to next_reset_at (1704067200)
[V2BoardAdapter] Cleaned user info response
```

2. 验证 API 响应格式是否符合 V2Board 标准

## 📚 相关文件

- **适配器实现**: `lib/sdk/flutter_xboard_sdk/lib/src/core/http/v2board_adapter.dart`
- **配置加载**: `lib/xboard/config/utils/config_file_loader.dart`
- **SDK 初始化**: `lib/xboard/sdk/src/xboard_client.dart`
- **HTTP 配置**: `lib/sdk/flutter_xboard_sdk/lib/src/core/http/http_config.dart`
- **配置示例**: `assets/config/xboard.config.example.yaml`

## 🔄 后续更新

适配器会随项目持续维护,如果 V2Board API 发生变化,只需修改适配器文件即可,无需改动业务代码。

## 💡 扩展适配

如需适配其他字段,编辑适配器文件:

```dart
// lib/sdk/flutter_xboard_sdk/lib/src/core/http/v2board_adapter.dart

void _adaptSubscriptionResponse(Map<String, dynamic> data) {
  // 添加新的字段转换逻辑
  if (subscriptionData.containsKey('v2board_new_field')) {
    subscriptionData['xboard_field'] = convertValue(...);
  }
}
```

---

**问题反馈**: 如遇到问题,请提供:
1. 配置文件内容
2. API 响应原始数据
3. 完整错误日志
