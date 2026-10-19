# harmony_develop

鸿蒙（HarmonyOS / ArkTS）开发笔记。**只有文档、脚本和经验记录，没有工程代码。**

这个仓库分两部分：

| 部分 | 回答什么 | 在哪 |
| --- | --- | --- |
| **一、HarmonyOS 开发入门** | 从零开始：怎么学、工程长什么样、ArkTS 和 ArkUI 怎么用、和 Android 怎么对应 | [`docs/start/`](docs/start/) |
| **二、本机工具链与日常操作** | 这台 Linux 机器上怎么装、怎么构建、怎么连平板、踩过哪些坑 | [`docs/toolchain/`](docs/toolchain/) |
| （附）发行与合规 | 注册、备案、软著、上架审核的流程与材料 | [`docs/README.md`](docs/README.md) |

> **文档定位**：命令与结论都经过本机实机核对。每条事实修正都留在 git 历史里（基线提交 `a7cd917` 是修正前的原始内容，之后的 commit 逐条订正）。
> 遇到与官方文档冲突的地方，以本仓库实测为准，但**先去看那条结论的出处**再决定信谁。

## 文档索引

### 一、HarmonyOS 开发入门

| 文件 | 回答的问题 |
| --- | --- |
| [01-学习路径](docs/start/01-学习路径.md) | 从零开始按什么顺序学，官方文档在哪，最省事的离线查阅方式 |
| [02-工程结构](docs/start/02-工程结构.md) | 工程目录里每个文件是干什么的，四个配置文件各管什么 |
| [03-ArkTS与ArkUI基础](docs/start/03-ArkTS与ArkUI基础.md) | ArkTS 的语言限制、ArkUI 声明式写法、状态管理、页面路由 |
| [04-从安卓迁移](docs/start/04-从安卓迁移.md) | 移植路线怎么选、Android→ArkTS 能力怎么对应、平台桥接怎么用 |

### 二、本机工具链与日常操作

| 文件 | 回答的问题 |
| --- | --- |
| [01-环境搭建](docs/toolchain/01-环境搭建.md) | Linux 上不装 IDE 怎么把工具链装起来、签名怎么配、模拟器怎么跑 |
| [02-日常操作](docs/toolchain/02-日常操作.md) | 构建/装机/拉起/看日志的日常循环，调试手段，命令速查 |
| [03-踩过的坑](docs/toolchain/03-踩过的坑.md) | 这台机器上真实踩到并被记录下来的坑，以及怎么恢复 |
| [04-发布签名与上架打包](docs/toolchain/04-发布签名与上架打包.md) | 手动申请发布证书、上架打包、源码混淆（上架前读这篇） |

### 附：发行与合规

| 文件 | 回答的问题 |
| --- | --- |
| [开发者注册与上架发行](docs/01-开发者注册与上架发行.md) | 个人能不能注册、注册要什么材料、从建应用到发布的每一步 |
| [备案与资质要求](docs/备案与资质要求.md) | 备案怎么走、软著要不要、哪些类目个人做不了 |

> 本仓库的实测环境：Arch Linux x86_64，CLT 26.0.0.851，`devecocli` 1.3.5，JDK 21，Node v22.23.2，
> 目标设备 Huawei MatePad Mini（API 26）。换环境后命令可能要跟着调，但坑大多相通。

## 脚本

| 文件 | 用途 |
| --- | --- |
| `scripts/env.sh` | 工具链环境变量，`source` 一下即可 |
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

1. HarmonyOS NEXT 起不再兼容 Android APK，现有安卓代码不能直接跑，UI 和业务都要用 ArkTS 重写。
2. 个人开发者可以注册并上架（免费、无年费），但拿不到华为账号一键登录等企业专属能力，游戏类也基本做不了。
3. APP 备案是上架的硬性前置条件，没备案的应用在华为应用市场会显示"暂不提供下载"，建议和开发并行启动。
4. DevEco Studio 只有 Windows / macOS / 鸿蒙电脑版（**没有 Linux 版**），但官方 Command Line Tools 有 Linux 版，Linux 上可以完全不装 IDE 完成开发、构建、签名与调试。

## 参考

- 原始文档（含已下载的原文）见 [docs/references/](docs/references/)。
- 给 Agent 的项目约定见 [AGENTS.md](AGENTS.md)。

> 资料基于 2026-10 时点整理，华为侧政策更新频繁，关键决策前请复核官方页面。当前版本参考：HarmonyOS 7（API 26）。
