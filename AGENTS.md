# AGENTS.md

给在这个仓库里工作的 Agent 用。人看的话，从 [README.md](README.md) 和 [docs/README.md](docs/README.md) 开始。

## 这个仓库是什么

**原生 HarmonyOS（ArkTS / ArkUI）开发的参考文档仓库。** 只有文档、脚本与经验记录，没有工程代码。

面向 Linux 命令行 + 鸿蒙平板实机，全程不需要 DevEco Studio。
**不涉及 OpenHarmony** —— 文档里出现的 `default/openharmony/toolchains` 是 CLT 的固定目录名，不是技术选型。

## 读文档的顺序

八篇，按「什么时候读」组织。**动手前至少读 01 和 07。**

| # | 文件 | 什么时候读 |
| --- | --- | --- |
| **01** | `docs/01-查证优先.md` | **写任何 ArkTS 代码之前** —— 不读它，后面几篇会把你带偏 |
| 02 | `docs/02-工具链与工具位置.md` | 换机器、配环境、命令找不到、版本对不上 |
| **03** | `docs/03-工程结构与代码规范.md` | **写代码时** —— 工程结构、ArkTS 限制、状态管理、代码约定 |
| 04 | `docs/04-开发工作流与命令.md` | 日常循环：改代码 → 构建 → 装机 → 拉起 |
| 05 | `docs/05-调试工作流与命令.md` | 出问题、要日志、要看屏幕、UI 不刷新 |
| **06** | `docs/06-打包与签名工作流.md` | **配签名、打上架包、开混淆 —— 上架前读这篇** |
| **07** | `docs/07-踩过的坑.md` | **踩坑前先查这里** —— 每条都是本机实测、有证据 |
| 08 | `docs/08-发行与合规.md` | 注册、备案、软著、提审（🧑 基本是人工流程，Agent 代替不了） |

`docs/references/` 是下载下来的官方原文（目前只有 ArkUI-X 那几篇），**平时不用读**。

## 运行环境假设

- 开发机是 **Linux**，没有 DevEco Studio（官方提供 Windows / macOS / 鸿蒙电脑版，**没有 Linux 版**）。
- 工具链用官方 **Command Line Tools (CLT)**，通过 PATH 暴露 `hvigorw`、`ohpm`、`hdc`、`codelinter`、`hstack`。
- 可能装了 `devecocli`（DevEco CLI）。**优先用 `devecocli`，它不存在时回退到裸 `hvigorw`/`hdc`。**
- 调试目标是一台**鸿蒙平板实机**，通过 `hdc` 的 USB 或 TCP 连接。
- 环境变量参考 `scripts/env.sh`，常用命令封装在 `scripts/dev.sh`。

## 改代码时的约定

- 语言用 **ArkTS**（不是纯 TypeScript）。不要用 `any`、不要运行时改对象结构、不要依赖 TS 的宽松类型推断 —— 这些在 ArkTS 编译期会直接报错。
- UI 用 **ArkUI 声明式**写法，状态驱动。不要照搬 Android 的「拿到 View 再 setText」。
- 页面状态用 `@State` / `@Prop` / `@Link` / `@Provide` / `@Consume` / `@Observed`。
- 工程配置文件：`app.json5`、`module.json5`、`build-profile.json5`、`oh-package.json5`。
- 构建系统是 **hvigor**，不是 Gradle；依赖声明的概念对应 `oh-package.json5`。

**完整规范与自查清单见 `docs/03-工程结构与代码规范.md`。**

## 不要做的事

- **不要凭记忆写鸿蒙 API**：先 `devecocli docs search <关键词>` 查本地文档，再写（见 `docs/01-查证优先.md`）。
- **不要提交 `build-profile.json5` 的签名改动，也不要把它写进 `.gitignore`**：该文件**保持被 Git 跟踪**（它同时含构建必需的 `products`/`modules` 配置，忽略它会让全新 clone 无法构建）；签名写进去的加密密码用 `git update-index --skip-worktree build-profile.json5` 隔离在本地。
- **不要提交任何签名材料**（`*.p12`、`*.cer`、`*.p7b`、`*.csr`）。不要把密码、私钥、token 写进仓库，也不要打日志输出密钥。
- **不要用 `devecocli run --uninstall`**：会把应用 `preferences/` 数据整个删掉。
- **不要随手改 `bundleName`**：它和 APP 备案、软著登记名称强绑定，改了要联动变更。
- **不要跳过联网子命令的代理问题**：`http_proxy`/`https_proxy` 会让 `devecocli` 的联网子命令**静默失败**（`auth status` 会打印 `Not logged in` 且 `EXIT=0`）。跑这类命令时套 `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY`。
- **不要拿 release 包去 `hdc install` 验证**：调试签名 + release 模式报 `9568322`，发布签名则官方明示不支持本地安装。推论是**凡是只在 release 生效的东西（源码混淆、release 优化）本地都验证不了**，只能走 AGC 邀请测试。别为此白跑设备测试 —— 见 `docs/06-打包与签名工作流.md`。

## 验证一个改动是否 work

改完代码至少要跑完这条链路，不能只看编译通过：

```bash
bash scripts/dev.sh build            # 编译
bash scripts/dev.sh run              # 装到平板并拉起
bash scripts/dev.sh log --level E    # 看错误日志
```

涉及 UI 的改动，用 `bash scripts/dev.sh ui` 导出节点树 + 截图确认实际渲染结果，别只靠代码推断。

**实机测试前先跑 `bash scripts/dev.sh keepawake`** —— 平板一锁屏，`aa start` 就报 `10106102`，而失败发生在应用启动之前，应用侧 API 救不了。收工记得 `keepawake-restore`。

## 写文档时的约定

- **区分「实测」与「未验证」**：实测结论直接写；来自第三方、没自己验过的，进 `docs/07-踩过的坑.md` 的「已知但未验证」一节，**不要混进正文当结论用**。
- **新增踩坑条目照固定格式写**（症状 → 为什么容易误判 → 机制与证据 → 怎么做），模板在 `docs/07-踩过的坑.md` 开头。
- 引用官方文档用 `devecocli docs read` 的完整路径（见 `docs/01-查证优先.md`），别只写 slug。

## 汇报要求

- 改完说清楚：改了什么、怎么验证的、哪些没验证。
- 涉及「上架/备案/资质」的结论，引用 `docs/08-发行与合规.md` 里对应的官方链接，不要自己编政策细节。
- 遇到工具链报错，先跑 `bash scripts/dev.sh doctor` 收集环境状态再判断。
