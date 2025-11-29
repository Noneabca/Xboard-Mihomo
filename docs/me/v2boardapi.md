# V2Board API 文档

## 概述

V2Board 是一个代理服务管理面板系统，提供完整的用户管理、订阅管理、支付系统等功能。

**基础URL**: `https://your-domain.com/api/v1` 或 `/api/v2`

**认证方式**: 
- Bearer Token (通过 `Authorization: Bearer {token}` header)
- 部分接口支持通过 `auth_data` 参数传递认证信息

**响应格式**: 所有API返回JSON格式，成功响应结构为 `{"data": ...}`

**错误处理**: HTTP状态码500表示错误，错误信息在响应体的 `message` 字段中

---

## 目录

1. [认证模块 (Passport)](#1-认证模块-passport)
2. [用户模块 (User)](#2-用户模块-user)
3. [订单模块 (Order)](#3-订单模块-order)
4. [订阅计划模块 (Plan)](#4-订阅计划模块-plan)
5. [服务器模块 (Server)](#5-服务器模块-server)
6. [工单模块 (Ticket)](#6-工单模块-ticket)
7. [邀请模块 (Invite)](#7-邀请模块-invite)
8. [优惠券模块 (Coupon)](#8-优惠券模块-coupon)
9. [知识库模块 (Knowledge)](#9-知识库模块-knowledge)
10. [公告模块 (Notice)](#10-公告模块-notice)
11. [Telegram模块](#11-telegram模块)
12. [统计模块 (Stat)](#12-统计模块-stat)
13. [客户端模块 (Client)](#13-客户端模块-client)
14. [访客模块 (Guest)](#14-访客模块-guest)
15. [管理员模块 (Admin)](#15-管理员模块-admin)
16. [员工模块 (Staff)](#16-员工模块-staff)
17. [服务器API (Server API)](#17-服务器api-server-api)

---

## 1. 认证模块 (Passport)

**基础路径**: `/api/v1/passport`

### 1.1 用户注册

**接口**: `POST /auth/register`

**请求参数**:
```json
{
  "email": "user@example.com",          // 必填，邮箱格式
  "password": "password123",             // 必填，最少8位
  "invite_code": "INVITE123",            // 条件必填，当 is_invite_force=1 时为必填
  "email_code": "123456",                // 条件必填，当 is_email_verify=1 时为必填
  "recaptcha_data": "recaptcha_token"    // 条件必填，当 is_recaptcha=1 时为必填
}
```

**响应示例**:
```json
{
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "auth_data": "encrypted_auth_data",
    "is_admin": false,
    "is_staff": false
  }
}
```

### 1.2 用户登录

**接口**: `POST /auth/login`

**请求参数**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应示例**:
```json
{
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "auth_data": "encrypted_auth_data",
    "is_admin": false
  }
}
```

### 1.3 忘记密码

**接口**: `POST /auth/forget`

**请求参数**:
```json
{
  "email": "user@example.com",
  "email_code": "123456",
  "password": "newpassword123"
}
```

**响应**: `{"data": true}`

### 1.4 Token登录

**接口**: `GET /auth/token2Login?verify={code}&redirect={page}`

### 1.5 获取快速登录链接

**接口**: `POST /auth/getQuickLoginUrl`

**需要认证**: ✅

**响应**: `{"data": "https://domain.com/#/login?verify=xxx"}`

### 1.6 邮件链接登录

**接口**: `POST /auth/loginWithMailLink`

**请求参数**: `{"email": "user@example.com", "redirect": "dashboard"}`

### 1.7 发送邮箱验证码

**接口**: `POST /comm/sendEmailVerify`

**请求参数**: `{"email": "user@example.com"}`

### 1.8 PV统计

**接口**: `POST /comm/pv`

**请求参数**: `{"inviter_id": 123}`

---

## 2. 用户模块 (User)

**基础路径**: `/api/v1/user`

**需要认证**: ✅ 所有接口

### 2.1 获取用户信息

**接口**: `GET /info`

**响应示例**:
```json
{
  "data": {
    "email": "user@example.com",
    "transfer_enable": 107374182400,    // 总流量（字节）
    "device_limit": 3,                  // 设备限制
    "last_login_at": 1637000000,
    "created_at": 1637000000,
    "banned": 0,                        // 是否封禁
    "auto_renewal": 0,                  // 自动续费
    "remind_expire": 1,                 // 到期提醒
    "remind_traffic": 1,                // 流量提醒
    "expired_at": 1640000000,           // 到期时间
    "balance": 0,                       // 余额（分）
    "commission_balance": 0,            // 佣金余额（分）
    "plan_id": 1,
    "discount": null,
    "commission_rate": null,
    "telegram_id": null,
    "uuid": "uuid-string",
    "avatar_url": "https://cravatar.cn/avatar/xxx"
  }
}
```

### 2.2 获取订阅信息

**接口**: `GET /getSubscribe`

**响应示例**:
```json
{
  "data": {
    "plan_id": 1,
    "token": "subscription_token",
    "expired_at": 1640000000,
    "u": 1073741824,                    // 上传流量（字节）
    "d": 2147483648,                    // 下载流量（字节）
    "transfer_enable": 107374182400,
    "device_limit": 3,
    "alive_ip": 2,                      // 在线设备数
    "subscribe_url": "https://domain.com/api/v1/client/subscribe?token=xxx",
    "reset_day": 30,                    // 重置日期
    "allow_new_period": 0,
    "plan": {
      "id": 1,
      "name": "Standard Plan"
    }
  }
}
```

### 2.3 获取统计数据

**接口**: `GET /getStat`

**响应**: `{"data": [2, 0, 5]}` // [未支付订单数, 未关闭工单数, 邀请人数]

### 2.4 修改密码

**接口**: `POST /changePassword`

**请求参数**:
```json
{
  "old_password": "oldpass123",
  "new_password": "newpass123"
}
```

### 2.5 更新用户设置

**接口**: `POST /update`

**请求参数**:
```json
{
  "auto_renewal": 1,      // 0或1
  "remind_expire": 1,
  "remind_traffic": 1
}
```

### 2.6 重置安全信息

**接口**: `GET /resetSecurity`

**功能**: 重置UUID和订阅Token

**响应**: `{"data": "new_subscribe_url"}`

### 2.7 解绑Telegram

**接口**: `GET /unbindTelegram`

### 2.8 兑换礼品卡

**接口**: `POST /redeemgiftcard`

**请求参数**: `{"giftcard": "GIFT-CARD-CODE"}`

**响应**:
```json
{
  "data": true,
  "type": 1,      // 1:余额 2:天数 3:流量 4:重置流量 5:订阅
  "value": 1000
}
```

### 2.9 提前重置周期

**接口**: `POST /newPeriod`

**功能**: 提前消耗订阅时长以重置流量

### 2.10 佣金划转

**接口**: `POST /transfer`

**请求参数**: `{"transfer_amount": 1000}` // 金额（分）

### 2.11 检查登录状态

**接口**: `GET /checkLogin`

**响应**: `{"data": {"is_login": true, "is_admin": false}}`

### 2.12 获取活跃会话

**接口**: `GET /getActiveSession`

### 2.13 删除活跃会话

**接口**: `POST /removeActiveSession`

**请求参数**: `{"session_id": "session-id"}`

### 2.14 获取快速登录URL

**接口**: `POST /getQuickLoginUrl`

**请求参数**: `{"redirect": "dashboard"}`

---

## 3. 订单模块 (Order)

**基础路径**: `/api/v1/user/order`

**需要认证**: ✅

### 3.1 创建订单

**接口**: `POST /save`

**请求参数**:
```json
{
  "plan_id": 1,                    // 必填，0为充值
  "period": "month_price",         // 必填
  "coupon_code": "COUPON123",      // 可选
  "deposit_amount": 10000          // 仅plan_id=0时需要（分）
}
```

**周期类型**: `month_price`, `quarter_price`, `half_year_price`, `year_price`, `two_year_price`, `three_year_price`, `onetime_price`, `reset_price`, `deposit`

**响应**: `{"data": "202301010000001"}` // 订单号

### 3.2 支付订单

**接口**: `POST /checkout`

**请求参数**:
```json
{
  "trade_no": "202301010000001",
  "method": 1,              // 支付方式ID
  "token": "stripe_token"   // Stripe支付时需要
}
```

**响应**:
```json
{
  "type": 0,    // -1:无需支付 0:二维码 1:跳转链接
  "data": "payment_url_or_qrcode"
}
```

### 3.3 获取订单列表

**接口**: `GET /fetch?status={0-4}`

**状态**: 0:待支付 1:开通中 2:已取消 3:已完成 4:已折抵

### 3.4 获取订单详情

**接口**: `GET /detail?trade_no={order_no}`

### 3.5 检查订单状态

**接口**: `GET /check?trade_no={order_no}`

### 3.6 获取支付方式

**接口**: `GET /getPaymentMethod`

### 3.7 取消订单

**接口**: `POST /cancel`

**请求参数**: `{"trade_no": "202301010000001"}`

---

## 4. 订阅计划模块 (Plan)

**基础路径**: `/api/v1/user/plan`

**需要认证**: ✅

### 4.1 获取订阅计划列表

**接口**: `GET /fetch`

**响应示例**:
```json
{
  "data": [
    {
      "id": 1,
      "name": "Standard Plan",
      "content": "Plan description",
      "transfer_enable": 100,        // GB
      "device_limit": 3,
      "speed_limit": null,           // Mbps
      "month_price": 1000,           // 分
      "quarter_price": 2700,
      "half_year_price": 5000,
      "year_price": 9000,
      "reset_price": 500,            // 流量重置价格
      "show": 1,                     // 是否显示
      "renew": 1                     // 是否可续费
    }
  ]
}
```

---

## 5. 服务器模块 (Server)

**基础路径**: `/api/v1/user/server`

**需要认证**: ✅

### 5.1 获取服务器列表

**接口**: `GET /fetch`

**响应示例**:
```json
{
  "data": [
    {
      "id": 1,
      "name": "Hong Kong #1",
      "type": "vmess",               // vmess, trojan, shadowsocks等
      "rate": "1.0",                 // 流量倍率
      "tags": ["IPLC", "BGP"],
      "host": "hk1.example.com",
      "port": 443,
      "network": "ws",               // tcp, ws, grpc等
      "tls": 1
    }
  ]
}
```

---

## 6. 工单模块 (Ticket)

**基础路径**: `/api/v1/user/ticket`

**需要认证**: ✅

### 6.1 获取工单列表

**接口**: `GET /fetch`

### 6.2 创建工单

**接口**: `POST /save`

**请求参数**:
```json
{
  "subject": "Connection Issue",
  "level": 1,              // 1:低 2:中 3:高
  "message": "Ticket content"
}
```

### 6.3 回复工单

**接口**: `POST /reply`

**请求参数**: `{"id": 1, "message": "Reply content"}`

### 6.4 关闭工单

**接口**: `POST /close`

**请求参数**: `{"id": 1}`

### 6.5 撤回工单

**接口**: `POST /withdraw`

**请求参数**: `{"id": 1}`

---

## 7. 邀请模块 (Invite)

**基础路径**: `/api/v1/user/invite`

**需要认证**: ✅

### 7.1 生成邀请码

**接口**: `GET /save`

**响应**: `{"data": "INVITE123"}`

### 7.2 获取邀请列表

**接口**: `GET /fetch`

### 7.3 获取邀请详情

**接口**: `GET /details`

---

## 8. 优惠券模块 (Coupon)

**基础路径**: `/api/v1/user/coupon`

**需要认证**: ✅

### 8.1 检查优惠券

**接口**: `POST /check`

**请求参数**:
```json
{
  "code": "COUPON123",
  "plan_id": 1,
  "period": "month_price"
}
```

**响应**:
```json
{
  "data": {
    "name": "10% Off",
    "type": 1,            // 1:金额 2:百分比
    "value": 10
  }
}
```

---

## 9. 知识库模块 (Knowledge)

**基础路径**: `/api/v1/user/knowledge`

**需要认证**: ✅

### 9.1 获取知识库列表

**接口**: `GET /fetch?category={id}`

### 9.2 获取知识库分类

**接口**: `GET /getCategory`

---

## 10. 公告模块 (Notice)

**基础路径**: `/api/v1/user/notice`

**需要认证**: ✅

### 10.1 获取公告列表

**接口**: `GET /fetch`

---

## 11. Telegram模块

**基础路径**: `/api/v1/user/telegram`

**需要认证**: ✅

### 11.1 获取Bot信息

**接口**: `GET /getBotInfo`

---

## 12. 统计模块 (Stat)

**基础路径**: `/api/v1/user/stat`

**需要认证**: ✅

### 12.1 获取流量日志

**接口**: `GET /getTrafficLog?start={timestamp}&end={timestamp}`

---

## 13. 客户端模块 (Client)

**基础路径**: `/api/v1/client`

### 13.1 获取订阅链接

**接口**: `GET /subscribe?token={token}`

**功能**: 根据User-Agent返回相应格式（base64、clash、surge等）

### 13.2 获取应用配置

**接口**: `GET /app/getConfig`

**需要认证**: ✅

### 13.3 获取应用版本

**接口**: `GET /app/getVersion`

**需要认证**: ✅

---

## 14. 访客模块 (Guest)

**基础路径**: `/api/v1/guest`

### 14.1 Telegram Webhook

**接口**: `POST /telegram/webhook`

### 14.2 支付回调

**接口**: `GET|POST /payment/notify/{method}/{uuid}`

### 14.3 获取配置

**接口**: `GET /comm/config`

**响应示例**:
```json
{
  "data": {
    "is_recaptcha": 0,           // 0:关闭 1:开启，控制是否需要 recaptcha_data
    "is_email_verify": 0,        // 0:关闭 1:开启，控制注册时是否需要 email_code
    "is_invite_force": 0,        // 0:可选 1:必填，控制注册时邀请码是否必填
    "app_name": "V2Board",
    "stop_register": 0           // 0:开放注册 1:关闭注册
  }
}
```

---

## 15. 管理员模块 (Admin)

**基础路径**: `/api/v1/{secure_path}`（secure_path在配置中定义）

**需要认证**: ✅ 管理员权限

### 15.1 配置管理

- `GET /config/fetch` - 获取配置
- `POST /config/save` - 保存配置
- `GET /config/getEmailTemplate` - 获取邮件模板
- `GET /config/getThemeTemplate` - 获取主题模板
- `POST /config/setTelegramWebhook` - 设置Telegram Webhook
- `POST /config/testSendMail` - 测试发送邮件

### 15.2 订阅计划管理

- `GET /plan/fetch` - 获取计划列表
- `POST /plan/save` - 保存计划
- `POST /plan/drop` - 删除计划
- `POST /plan/update` - 更新计划
- `POST /plan/sort` - 排序计划

### 15.3 服务器管理

**服务器组**:
- `GET /server/group/fetch`
- `POST /server/group/save`
- `POST /server/group/drop`

**路由管理**:
- `GET /server/route/fetch`
- `POST /server/route/save`
- `POST /server/route/drop`

**节点管理**:
- `GET /server/manage/getNodes`
- `POST /server/manage/sort`

**各类型服务器** (trojan, vmess, shadowsocks, tuic, hysteria, vless, anytls, v2node):
- `POST /server/{type}/save`
- `POST /server/{type}/drop`
- `POST /server/{type}/update`
- `POST /server/{type}/copy`

### 15.4 订单管理

- `GET /order/fetch` - 获取订单列表
- `POST /order/update` - 更新订单
- `POST /order/assign` - 分配订单
- `POST /order/paid` - 标记已支付
- `POST /order/cancel` - 取消订单
- `POST /order/detail` - 订单详情

### 15.5 用户管理

- `GET /user/fetch` - 获取用户列表
- `POST /user/update` - 更新用户
- `GET /user/getUserInfoById` - 根据ID获取用户信息
- `POST /user/generate` - 生成用户
- `POST /user/dumpCSV` - 导出CSV
- `POST /user/sendMail` - 发送邮件
- `POST /user/ban` - 封禁/解封用户
- `POST /user/resetSecret` - 重置密钥
- `POST /user/delUser` - 删除用户
- `POST /user/allDel` - 批量删除
- `POST /user/setInviteUser` - 设置邀请人

### 15.6 统计管理

- `GET /stat/getStat` - 获取统计数据
- `GET /stat/getOverride` - 获取概览数据
- `GET /stat/getServerLastRank` - 服务器昨日排名
- `GET /stat/getServerTodayRank` - 服务器今日排名
- `GET /stat/getUserLastRank` - 用户昨日排名
- `GET /stat/getUserTodayRank` - 用户今日排名
- `GET /stat/getOrder` - 订单统计
- `GET /stat/getStatUser` - 用户统计
- `GET /stat/getRanking` - 排行榜
- `GET /stat/getStatRecord` - 统计记录

### 15.7 公告管理

- `GET /notice/fetch` - 获取公告列表
- `POST /notice/save` - 保存公告
- `POST /notice/update` - 更新公告
- `POST /notice/drop` - 删除公告
- `POST /notice/show` - 显示/隐藏公告

### 15.8 工单管理

- `GET /ticket/fetch` - 获取工单列表
- `POST /ticket/reply` - 回复工单
- `POST /ticket/close` - 关闭工单

### 15.9 优惠券管理

- `GET /coupon/fetch` - 获取优惠券列表
- `POST /coupon/generate` - 生成优惠券
- `POST /coupon/drop` - 删除优惠券
- `POST /coupon/show` - 显示/隐藏优惠券

### 15.10 礼品卡管理

- `GET /giftcard/fetch` - 获取礼品卡列表
- `POST /giftcard/generate` - 生成礼品卡
- `POST /giftcard/drop` - 删除礼品卡

### 15.11 知识库管理

- `GET /knowledge/fetch` - 获取知识库列表
- `GET /knowledge/getCategory` - 获取分类
- `POST /knowledge/save` - 保存知识库
- `POST /knowledge/show` - 显示/隐藏
- `POST /knowledge/drop` - 删除知识库
- `POST /knowledge/sort` - 排序

### 15.12 支付管理

- `GET /payment/fetch` - 获取支付方式列表
- `GET /payment/getPaymentMethods` - 获取可用支付方法
- `POST /payment/getPaymentForm` - 获取支付表单
- `POST /payment/save` - 保存支付方式
- `POST /payment/drop` - 删除支付方式
- `POST /payment/show` - 显示/隐藏支付方式
- `POST /payment/sort` - 排序

### 15.13 系统管理

- `GET /system/getSystemStatus` - 获取系统状态
- `GET /system/getQueueStats` - 获取队列统计
- `GET /system/getQueueWorkload` - 获取队列负载
- `GET /system/getQueueMasters` - 获取队列管理器
- `GET /system/getSystemLog` - 获取系统日志

### 15.14 主题管理

- `GET /theme/getThemes` - 获取主题列表
- `POST /theme/saveThemeConfig` - 保存主题配置
- `POST /theme/getThemeConfig` - 获取主题配置

---

## 16. 员工模块 (Staff)

**基础路径**: `/api/v1/staff`

**需要认证**: ✅ 员工权限

### 16.1 工单管理

- `GET /ticket/fetch`
- `POST /ticket/reply`
- `POST /ticket/close`

### 16.2 用户管理

- `POST /user/update`
- `GET /user/getUserInfoById`
- `POST /user/sendMail`
- `POST /user/ban`

### 16.3 计划管理

- `GET /plan/fetch`

### 16.4 公告管理

- `GET /notice/fetch`
- `POST /notice/save`
- `POST /notice/update`
- `POST /notice/drop`

---

## 17. 服务器API (Server API)

**基础路径**: `/api/v1/server` 和 `/api/v2/server`

**认证方式**: 通过 `token` 参数（server_token）和 `node_id` 参数

### 17.1 V1 服务器API

**接口**: `ANY /server/{class}/{action}`

**动态路由**: 根据class和action调用相应的服务器控制器方法

**支持的控制器**:
- `DeepbworkController`
- `ShadowsocksTidalabController`
- `TrojanTidalabController`
- `UniProxyController`

### 17.2 V2 服务器配置

**接口**: `POST /api/v2/server/config`

**请求参数**:
```json
{
  "token": "server_token",
  "node_id": 1
}
```

**响应示例**:
```json
{
  "listen_ip": "0.0.0.0",
  "server_port": 443,
  "network": "ws",
  "protocol": "vmess",
  "tls": 1,
  "encryption": "auto",
  "flow": null,
  "cipher": "aes-128-gcm",
  "up_mbps": 100,
  "down_mbps": 100,
  "ignore_client_bandwidth": false,
  "base_config": {
    "push_interval": 60,
    "pull_interval": 60,
    "node_report_min_traffic": 0,
    "device_online_min_traffic": 0
  },
  "routes": []
}
```

---

## 附录

### 通用响应格式

**成功响应**:
```json
{
  "data": "返回数据"
}
```

**错误响应** (HTTP 500):
```json
{
  "message": "错误信息"
}
```

### 常用数据类型说明

- **流量单位**: 字节 (Byte)
- **金额单位**: 分 (Cent)
- **时间戳**: Unix时间戳（秒）
- **布尔值**: 0或1

### 订阅周期类型

- `month_price`: 月付
- `quarter_price`: 季付 (3个月)
- `half_year_price`: 半年付 (6个月)
- `year_price`: 年付 (12个月)
- `two_year_price`: 两年付
- `three_year_price`: 三年付
- `onetime_price`: 一次性（永久）
- `reset_price`: 流量重置
- `deposit`: 充值

### 订单状态

- `0`: 待支付
- `1`: 开通中
- `2`: 已取消
- `3`: 已完成
- `4`: 已折抵

### 工单级别

- `1`: 低
- `2`: 中
- `3`: 高

### 礼品卡类型

- `1`: 余额
- `2`: 天数
- `3`: 流量
- `4`: 重置流量
- `5`: 订阅计划

---

**文档生成时间**: 2023

**V2Board 版本**: 基于项目代码分析生成

**注意**: 实际使用时请根据系统配置调整相应参数和端点路径。