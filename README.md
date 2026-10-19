# harmony_develop

鸿蒙（HarmonyOS / ArkTS）**原生**开发参考。**只有文档、脚本和经验记录，没有工程代码。**

面向 **Linux 命令行 + 鸿蒙平板实机**，全程不需要 DevEco Studio。
**不涉及 OpenHarmony** —— 文档里出现的 `default/openharmony/toolchains` 是 CLT 的固定目录名，不是技术选型。

## 文档

**完整索引（含每篇「什么时候读」）在 [docs/README.md](docs/README.md)。** 八篇：

1. [查证优先](docs/01-查证优先.md)
2. [工具链与工具位置](docs/02-工具链与工具位置.md)
3. [工程结构与代码规范](docs/03-工程结构与代码规范.md)
4. [开发工作流与命令](docs/04-开发工作流与命令.md)
5. [调试工作流与命令](docs/05-调试工作流与命令.md)
6. [打包与签名工作流](docs/06-打包与签名工作流.md)
7. [踩过的坑](docs/07-踩过的坑.md)
8. [发行与合规](docs/08-发行与合规.md)

> **文档定位**：命令与结论都经过本机实机核对。每条事实修正都留在 git 历史里
> （基线提交 `a7cd917` 是修正前的原始内容，之后的 commit 逐条订正）。
> 遇到与官方文档冲突的地方，以本仓库实测为准，但**先去看那条结论的出处**再决定信谁。
> **没实测过的说法一律标「未验证」**（见 [07](docs/07-踩过的坑.md) 末尾）。

## 四条最关键结论

1. **DevEco Studio 没有 Linux 版**，但官方 Command Line Tools 有 —— Linux 上可以完全不装 IDE
   完成开发、构建、签名与调试（[02](docs/02-工具链与工具位置.md)）。
2. **ArkTS 不是 TypeScript。** `any`、解构、运行时改对象结构这些 TS 习惯在 ArkTS 里**编译期就报错**
   （[03](docs/03-工程结构与代码规范.md)）。
3. **调试签名和发布签名必须两套并存。** 换签名 = 清数据；而 release 包**本地装不上**，
   所以源码混淆这类只在 release 生效的东西**本地验证不了**（[06](docs/06-打包与签名工作流.md)）。
4. **APP 备案是上架的硬性前置条件**，没备案的应用在华为应用市场会显示「暂不提供下载」。
   备案 5~20 天、软著 1~2 个月，**建议和开发并行启动**（[08](docs/08-发行与合规.md)）。

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

> `scripts/dev.sh` 会自动 source 仓库根的 `.env.local`（gitignored，可选），
> 把 `HDOS_DEVICE_SERIAL` / `HDOS_BUNDLE_NAME` 映射成 `HDOS_TARGET` / `BUNDLE_NAME`。

---

## 给 Agent 的约定

### 一、动手前的阅读顺序

**必读 [01 查证优先](docs/01-查证优先.md) 和 [07 踩过的坑](docs/07-踩过的坑.md)**，
其余按当前任务查（完整说明见 [docs/README.md](docs/README.md)）：

| 任务 | 读 |
| --- | --- |
| 写 / 改 ArkTS 代码 | 03（工程结构、语言限制、状态管理、代码约定） |
| 构建、装机、拉起 | 04 |
| 查问题、要日志、看屏幕 | 05 |
| 配签名、打上架包、开混淆 | 06 |
| 注册、备案、软著、提审 | 08（**人工流程，Agent 代替不了**） |

### 二、运行环境假设

- 开发机是 **Linux**，没有 DevEco Studio（官方只有 Windows / macOS / 鸿蒙电脑版）。
- 工具链用官方 **Command Line Tools (CLT)**，通过 PATH 暴露 `hvigorw`、`ohpm`、`hdc`、`codelinter`、`hstack`。
- 可能装了 `devecocli`（DevEco CLI）。**优先用它，不存在时回退到裸 `hvigorw`/`hdc`。**
- 调试目标是一台**鸿蒙平板实机**，通过 `hdc` 的 USB 或 TCP 连接。
- 环境变量参考 `scripts/env.sh`，常用命令封装在 `scripts/dev.sh`。

### 三、红线

- **不要凭记忆写鸿蒙 API**：先 `devecocli docs search <关键词>` 查本地文档，再写（见 [01](docs/01-查证优先.md)）。
- **不要提交 `build-profile.json5` 的签名改动，也不要把它写进 `.gitignore`**：该文件**保持被 Git 跟踪**（它同时含构建必需的 `products`/`modules` 配置，忽略它会让全新 clone 无法构建）；签名写进去的加密密码用 `git update-index --skip-worktree build-profile.json5` 隔离在本地。
- **不要提交任何签名材料**（`*.p12`、`*.cer`、`*.p7b`、`*.csr`）。不要把密码、私钥、token 写进仓库，也不要打日志输出密钥。
- **不要用 `devecocli run --uninstall`**：会把应用 `preferences/` 数据整个删掉。
- **不要随手改 `bundleName`**：它和 APP 备案、软著登记名称强绑定，改了要联动变更。
- **不要跳过联网子命令的代理问题**：`http_proxy`/`https_proxy` 会让 `devecocli` 的联网子命令**静默失败**（`auth status` 会打印 `Not logged in` 且 `EXIT=0`）。跑这类命令时套 `env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY`。
- **不要拿 release 包去 `hdc install` 验证**：调试签名 + release 模式报 `9568322`，发布签名则官方明示不支持本地安装。推论是**凡是只在 release 生效的东西（源码混淆、release 优化）本地都验证不了**，只能走 AGC 邀请测试 —— 见 [06](docs/06-打包与签名工作流.md)。

### 四、验证一个改动是否 work

改完代码至少要跑完这条链路，不能只看编译通过：

```bash
bash scripts/dev.sh build            # 编译
bash scripts/dev.sh run              # 装到平板并拉起
bash scripts/dev.sh log --level E    # 看错误日志
```

涉及 UI 的改动，用 `bash scripts/dev.sh ui` 导出节点树 + 截图确认实际渲染结果，别只靠代码推断。

**实机测试前先跑 `bash scripts/dev.sh keepawake`** —— 平板一锁屏，`aa start` 就报 `10106102`，而失败发生在应用启动之前，应用侧 API 救不了。收工记得 `keepawake-restore`。

### 五、写文档时的约定

- **区分「实测」与「未验证」**：实测结论直接写；来自第三方、没自己验过的，进 [07](docs/07-踩过的坑.md) 的「已知但未验证」一节，**不要混进正文当结论用**。
- **新增踩坑条目照固定格式写**（症状 → 为什么容易误判 → 机制与证据 → 怎么做），模板在 [07](docs/07-踩过的坑.md) 开头。
- 引用官方文档用 `devecocli docs read` 的完整路径（见 [01](docs/01-查证优先.md)），别只写 slug。
- **新增 / 重命名文档时只改一处索引**：[docs/README.md](docs/README.md)。本文件只列篇名，不写每篇的说明。

### 六、汇报要求

- 改完说清楚：改了什么、怎么验证的、哪些没验证。
- 涉及「上架/备案/资质」的结论，引用 [08](docs/08-发行与合规.md) 里对应的官方链接，不要自己编政策细节。
- 遇到工具链报错，先跑 `bash scripts/dev.sh doctor` 收集环境状态再判断。

---

## 参考

- 原始文档（含已下载的官方原文）见 [docs/references/](docs/references/)。
- 这个仓库的定位是「工具链 + 经验」，具体产品项目的文档在各项目自己仓库里。

> 资料基于 2026-10 时点整理，华为侧政策更新频繁，关键决策前请复核官方页面。
> 当前版本参考：HarmonyOS 7（API 26）。
