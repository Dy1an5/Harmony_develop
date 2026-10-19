# harmony_develop

鸿蒙（HarmonyOS / ArkTS）开发参考。**只有文档、脚本和经验记录，没有工程代码。**

面向**原生 HarmonyOS 开发**（不涉及 OpenHarmony），目标环境是 **Linux 命令行 + 鸿蒙平板实机**，
全程不需要 DevEco Studio。

## 文档

八篇，在 [`docs/`](docs/)。索引见 [docs/README.md](docs/README.md)。

| # | 文件 | 什么时候读 |
| --- | --- | --- |
| 01 | [查证优先](docs/01-查证优先.md) | **写任何 ArkTS 代码之前** —— 官方文档入口与离线检索 |
| 02 | [工具链与工具位置](docs/02-工具链与工具位置.md) | 换机器、配环境、命令找不到、版本对不上 |
| 03 | [工程结构与代码规范](docs/03-工程结构与代码规范.md) | **写代码时** —— 工程结构、ArkTS 限制、状态管理、代码约定 |
| 04 | [开发工作流与命令](docs/04-开发工作流与命令.md) | 日常循环：改代码 → 构建 → 装机 → 拉起 |
| 05 | [调试工作流与命令](docs/05-调试工作流与命令.md) | 出问题、要日志、要看屏幕、UI 不刷新 |
| 06 | [打包与签名工作流](docs/06-打包与签名工作流.md) | 配签名、打上架包、开混淆 |
| 07 | [踩过的坑](docs/07-踩过的坑.md) | **踩坑前先查这里** —— 每条都是本机实测、有证据 |
| 08 | [发行与合规](docs/08-发行与合规.md) | 注册、备案、软著、提审（🧑 基本是人工流程） |

> **文档定位**：命令与结论都经过本机实机核对。每条事实修正都留在 git 历史里
> （基线提交 `a7cd917` 是修正前的原始内容，之后的 commit 逐条订正）。
> 遇到与官方文档冲突的地方，以本仓库实测为准，但**先去看那条结论的出处**再决定信谁。
> **没实测过的说法一律标「未验证」**（见 [07](docs/07-踩过的坑.md) 末尾）。

## 脚本

| 文件 | 用途 |
| --- | --- |
| `scripts/env.sh` | 工具链环境变量，`source` 一下即可（幂等） |
| `scripts/dev.sh` | 构建 / 装包 / 运行 / 看日志 / 截图 / 取 UDID / keepawake / hotreload-stop |
| `tools/fetch-official-docs.sh` | 在自己有网络的机器上拉取可下载的官方文档 |

```bash
source scripts/env.sh
bash scripts/dev.sh doctor     # 看工具链和设备状态
bash scripts/dev.sh build      # 编译
bash scripts/dev.sh keepawake  # 实机测试前：让平板别锁屏（否则 aa start 报 10106102）
bash scripts/dev.sh run        # 装到平板并拉起
bash scripts/dev.sh log        # 看日志
bash scripts/dev.sh keepawake-restore   # 收工还原
```

## 四条最关键结论

1. **DevEco Studio 没有 Linux 版**，但官方 Command Line Tools 有 —— Linux 上可以完全不装 IDE
   完成开发、构建、签名与调试（[02](docs/02-工具链与工具位置.md)）。
2. **ArkTS 不是 TypeScript。** `any`、解构、运行时改对象结构这些 TS 习惯在 ArkTS 里**编译期就报错**
   （[03](docs/03-工程结构与代码规范.md)）。
3. **调试签名和发布签名必须两套并存。** 换签名 = 清数据；而 release 包**本地装不上**，
   所以源码混淆这类只在 release 生效的东西**本地验证不了**（[06](docs/06-打包与签名工作流.md)）。
4. **APP 备案是上架的硬性前置条件**，没备案的应用在华为应用市场会显示「暂不提供下载」。
   备案 5~20 天、软著 1~2 个月，**建议和开发并行启动**（[08](docs/08-发行与合规.md)）。

## 参考

- 原始文档（含已下载的官方原文）见 [docs/references/](docs/references/)。
- 给 Agent 的项目约定见 [AGENTS.md](AGENTS.md)。

> 资料基于 2026-10 时点整理，华为侧政策更新频繁，关键决策前请复核官方页面。
> 当前版本参考：HarmonyOS 7（API 26）。
