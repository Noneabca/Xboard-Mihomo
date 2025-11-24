# Git Fork 工作流配置

## 配置时间
2025-11-24

## 配置内容

### 主仓库配置

**仓库路径**: `C:\Users\Administrator\Documents\Xboard-Mihomo`

- **origin** (个人仓库): `https://github.com/Noneabca/Xboard-Mihomo.git`
- **upstream** (上游仓库): `https://github.com/hakimi-x/Xboard-Mihomo.git`

### 子模块配置

**flutter_xboard_sdk**

路径: `lib/sdk/flutter_xboard_sdk/`

- **origin** (个人仓库): `https://github.com/Noneabca/flutter_xboard_sdk.git`
- **upstream** (上游仓库): `https://github.com/hakimi-x/flutter_xboard_sdk.git`

## 日常使用

### 开发主项目代码

```bash
# 修改代码后提交
git add .
git commit -m "你的修改说明"
git push origin main
```

### 开发 SDK 子模块

```bash
# 进入子模块
cd lib/sdk/flutter_xboard_sdk

# 提交修改
git add .
git commit -m "SDK修改"
git push origin main

# 回到主项目，更新子模块引用
cd ../../..
git add lib/sdk/flutter_xboard_sdk
git commit -m "chore: update SDK submodule"
git push origin main
```

### 同步上游更新

#### 同步主项目

```bash
# 拉取上游更新
git pull upstream main

# 推送到个人仓库
git push origin main
```

#### 同步子模块

```bash
# 进入子模块
cd lib/sdk/flutter_xboard_sdk

# 拉取上游更新
git pull upstream main
git push origin main

# 回到主项目，更新引用
cd ../../..
git add lib/sdk/flutter_xboard_sdk
git commit -m "chore: sync upstream SDK"
git push origin main
```

### 创建功能分支（推荐）

```bash
# 创建新分支
git checkout -b feature/功能名称

# 开发完成后
git add .
git commit -m "feat: 添加新功能"
git push origin feature/功能名称
```

## 配置命令记录

### 主仓库配置

```bash
cd "C:\Users\Administrator\Documents\Xboard-Mihomo"

# 重命名原远程为 upstream
git remote rename origin upstream

# 添加个人仓库为 origin
git remote add origin https://github.com/Noneabca/Xboard-Mihomo.git

# 提交并推送初始设置
git add .
git commit -m "chore: initial setup for my fork"
git push origin main
```

### 子模块配置

```bash
cd lib/sdk/flutter_xboard_sdk

# 重命名原远程为 upstream
git remote rename origin upstream

# 添加个人仓库为 origin
git remote add origin https://github.com/Noneabca/flutter_xboard_sdk.git

# 切换到 main 分支
git checkout main

# 提交并推送
git add pubspec.lock
git commit -m "chore: update pubspec.lock"
git push origin main
```

## 优势

- ✅ 可以自由修改代码，不影响上游仓库
- ✅ 随时同步上游更新
- ✅ 修改安全保存在个人 GitHub 仓库
- ✅ 支持分支开发，代码管理更清晰
