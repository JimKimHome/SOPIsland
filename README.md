# OrSOP

OrSOP 是一款用 Flutter 开发的移动端 SOP 执行与管理工具。它把流程拆成可勾选的步骤和子步骤，适合门店巡检、内容发布、每日开工、团队交接等重复性工作。

## 当前功能

- 首页执行看板：展示未完成实例、今日建议和最近执行记录。
- 我的 SOP：管理流程库，支持搜索、筛选置顶、查看详情、执行、编辑和删除。
- SOP 编辑：编辑名称、场景、描述、步骤和子步骤；子步骤支持空白新增、多行自适应、删除和长按拖拽排序。
- 执行模式：按步骤勾选检查项，支持上一步/下一步、总览跳转、完成统计。
- 暂存实例：执行中可“暂存并退出”，同一 SOP 可保留多个进行中实例，并在首页继续。
- 日历提醒：为 SOP 设置一次、每天、每周或每月提醒，并调用系统日历确认保存。
- AI 生成 SOP：描述需求后生成可编辑的 SOP 草稿。
- AI 优化 SOP：在编辑页输入复盘意见，让模型基于现有 SOP 生成优化版本。
- AI 配置：支持 OpenAI-compatible `/v1/chat/completions` 接口，可配置 Base URL、模型名和 API Key。
- 备份导入导出：导出 `.orsop.json` 备份；导入时可选择合并或覆盖。
- 本地存储：SOP、执行记录、提醒信息和 AI 配置保存在本机 SharedPreferences 中。

## 主要页面

- `首页`：面向“今天要做什么”，优先显示继续执行和建议执行。
- `我的 SOP`：流程资产库，负责新建、编辑、运行和维护 SOP。
- `AI 生成 SOP`：从自然语言需求生成流程。
- `设置`：管理 API 配置和 SOP 备份。

## AI 接入

当前 AI 调用使用 OpenAI-compatible Chat Completions 格式：

```text
POST {Base URL}/chat/completions
Authorization: Bearer {API Key}
```

配置入口：`首页右上角设置` 或 `AI 生成 SOP` 页面右上角设置。

可用服务包括 OpenAI、DeepSeek、MiniMax 或其他兼容代理。配置完成后可以使用：

- AI 生成 SOP
- AI 优化已有 SOP

## 数据与备份

应用数据默认保存在本机：

- SOP 列表与执行记录：`sop_island_sops_v1`
- AI 配置：`sop_island_ai_config_v1`

备份文件格式为：

```text
OrSOP-backup-YYYYMMDD-HHMM.orsop.json
```

导入模式：

- 合并导入：保留当前 SOP，并用备份中同 ID 的 SOP 更新旧版本。
- 覆盖当前：清空当前 SOP 后导入备份内容。

## 开发环境

项目使用 Flutter。

```bash
flutter --version
flutter pub get
flutter analyze --no-pub
```

## 本地运行

查看设备：

```bash
flutter devices
```

运行到指定设备：

```bash
flutter run -d <device-id>
```

无线 Android 设备示例：

```bash
adb connect 192.168.x.x:port
flutter run -d 192.168.x.x:port
```

## 构建与安装 Android APK

构建 release APK：

```bash
flutter build apk
```

安装到指定设备：

```bash
flutter install -d <device-id>
```

如果刚修改过代码，请先执行 `flutter build apk`，再执行 `flutter install`，否则可能安装到旧的 `app-release.apk`。

## 项目结构

```text
lib/
  app_shell.dart              # 底部导航、首页/我的 SOP 容器、设置和备份入口
  app_controller.dart         # 全局状态、加载保存、导入导出协调
  main.dart                   # 我的 SOP、详情、编辑、执行、提醒等主交互
  models/
    sop.dart                  # SOP、步骤、提醒、执行暂存、模板和本地存储模型
    ai_config.dart            # AI 服务配置模型
    sop_backup.dart           # 备份格式
  screens/
    home_hub.dart             # 首页执行看板
    ai_generate_screen.dart   # AI 生成 SOP
    ai_config_screen.dart     # AI 配置
    settings_screen.dart      # 设置、导入导出
  services/
    ai_sop_service.dart       # AI 生成/优化请求
    calendar_service.dart     # 系统日历提醒
    backup_file_service.dart  # 原生文件导入导出桥接
  theme/
    app_theme.dart            # 主题、颜色、通用装饰
```

## Android 原生能力

Android 侧包名：

```text
com.sopisland.app
```

当前包含两个 MethodChannel：

- `com.sopisland.app/calendar`：创建系统日历提醒。
- `com.sopisland.app/backup`：保存和打开 `.orsop.json` 备份文件。

## 备注

这是一个以移动端使用为主的 Flutter 项目。README 反映当前代码中的功能状态，后续如果新增页面、数据结构或原生能力，应同步更新这里。
