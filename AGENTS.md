# AGENTS.md

给在这个仓库里工作的 Agent 用。人看的话，从 [README.md](README.md) 和 [docs/README.md](docs/README.md) 开始。

## 这个仓库是什么

把现有 Android 应用移植为原生鸿蒙（HarmonyOS / ArkTS）应用的准备仓库。
**当前状态：只有文档、脚本与经验记录，没有工程代码**。

文档分两部分，索引见 `docs/README.md`。**动手前按需要读：**

写代码 / 理解鸿蒙本身：

- `docs/start/01-学习路径.md`：学习顺序、官方文档入口、`devecocli docs` 离线检索
- `docs/start/02-工程结构.md`：工程目录与四个配置文件各管什么
- `docs/start/03-ArkTS与ArkUI基础.md`：ArkTS 限制、ArkUI 声明式、状态管理、路由
- `docs/start/04-从安卓迁移.md`：移植路线、能力映射、平台桥接

在这台机器上干活：

- `docs/toolchain/01-环境搭建.md`：工具链安装、签名、模拟器、能力边界
- `docs/toolchain/02-日常操作.md`：构建/装机/拉起/看日志、调试手段、命令速查
- `docs/toolchain/03-踩过的坑.md`：**真实踩到的坑与恢复方式，踩坑前先查这里**

发行与合规：

- `docs/01-开发者注册与上架发行.md`、`docs/备案与资质要求.md`

## 运行环境假设

- 开发机是 **Linux**，没有 DevEco Studio（官方提供 Windows / macOS / 鸿蒙电脑版，**没有 Linux 版**）。
- 工具链用官方 **Command Line Tools (CLT)**，通过 PATH 暴露 `hvigorw`、`ohpm`、`hdc`、`codelinter`、`hstack`。
- 可能装了 `devecocli`（DevEco CLI）。**优先用 `devecocli`，它不存在时回退到裸 `hvigorw`/`hdc`。**
- 调试目标是一台**鸿蒙平板实机**，通过 `hdc` 的 USB 或 TCP 连接。
- 环境变量参考 `scripts/env.sh`，常用命令封装在 `scripts/dev.sh`。

## 改代码时的约定

- 语言用 **ArkTS**（不是纯 TypeScript）。不要用 `any`、不要运行时改对象结构、不要依赖 TS 的宽松类型推断 —— 这些在 ArkTS 编译期会直接报错。
- UI 用 **ArkUI 声明式**写法，状态驱动。不要照搬 Android 的"拿到 View 再 setText"。
- 页面状态用 `@State` / `@Prop` / `@Link` / `@Provide` / `@Consume` / `@Observed`。
- 工程配置文件：`app.json5`、`module.json5`、`build-profile.json5`、`oh-package.json5`。
- 构建系统是 **hvigor**，不是 Gradle；依赖声明的概念对应 `oh-package.json5`。

## 不要做的事

- **不要提交 `build-profile.json5` 的签名改动，也不要把它写进 `.gitignore`**：该文件**保持被 Git 跟踪**（它同时含构建必需的 `products`/`modules` 配置，忽略它会让全新 clone 无法构建）；签名写进去的加密密码用 `git update-index --skip-worktree build-profile.json5` 隔离在本地。
- **不要提交任何签名材料**（`*.p12`、`*.cer`、`*.p7b`、`*.csr`）。不要把密码、私钥、token 写进仓库，也不要打日志输出密钥。
- **不要用 `devecocli run --uninstall`**：会把应用 `preferences/` 数据整个删掉。
- **不要随手改 `bundleName`**：它和 APP 备案、软著登记名称强绑定，改了要联动变更。
- **不要凭记忆写鸿蒙 API**：先 `devecocli docs search <关键词>` 查本地文档，再写。
- **不要跳过联网子命令的代理问题**：`http_proxy`/`https_proxy` 会让 `devecocli` 的联网子命令**静默失败**（`auth status` 会打印 `Not logged in` 且 `EXIT=0`）。跑这类命令时套 `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY`。

## 验证一个改动是否work

改完代码至少要跑完这条链路，不能只看编译通过：

```bash
bash scripts/dev.sh build            # 编译
bash scripts/dev.sh run              # 装到平板并拉起
bash scripts/dev.sh log --level E    # 看错误日志
```

涉及 UI 的改动，用 `bash scripts/dev.sh ui` 导出节点树 + 截图确认实际渲染结果，别只靠代码推断。

**实机测试前先跑 `bash scripts/dev.sh keepawake`** —— 平板一锁屏，`aa start` 就报 `10106102`，而失败发生在应用启动之前，应用侧 API 救不了。收工记得 `keepawake-restore`。

## 汇报要求

- 改完说清楚：改了什么、怎么验证的、哪些没验证。
- 涉及"上架/备案/资质"的结论，引用 `docs/` 里对应的官方链接，不要自己编政策细节。
- 遇到工具链报错，先跑 `bash scripts/dev.sh doctor` 收集环境状态再判断。
