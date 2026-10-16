# references 目录说明

这里放**下载下来的原始文档**，以及下载不到的东西的说明。

## 已下载（原文完整）

| 文件 | 来源 | 许可 |
| --- | --- | --- |
| `arkui-x/ArkUI-X概览-zh.md` | https://raw.githubusercontent.com/arkui-x/docs/master/zh-cn/ArkUI-X-Overview-zh.md | Apache-2.0 |
| `arkui-x/平台桥接介绍-zh.md` | https://raw.githubusercontent.com/arkui-x/docs/master/zh-cn/application-dev/quick-start/platform-bridge-introduction.md | Apache-2.0 |
| `arkui-x/平台桥接开发指南-Android.md` | https://raw.githubusercontent.com/arkui-x/docs/master/zh-cn/application-dev/tutorial/how-to-use-bridge-on-android.md | Apache-2.0 |
| `arkui-x/平台桥接开发指南-iOS.md` | https://raw.githubusercontent.com/arkui-x/docs/master/zh-cn/application-dev/tutorial/how-to-use-bridge-on-ios.md | Apache-2.0 |

ArkUI-X 是华为官方的开源跨平台框架项目，文档仓以 Apache-2.0 发布，可以自由转载保留出处。

> **哪篇讲什么**（`06` 里引用的创建时机出自**开发指南**那两篇，不是「介绍」那篇）：
> - `平台桥接介绍-zh.md` —— 机制简介、使用场景、JSON/二进制**数据类型支持表**与传输上限（string 2MB、ArrayBuffer 20MB、数字 ±2^53）。
> - `平台桥接开发指南-Android.md` —— Android 侧落地：**创建时机**（分 SDK < / ≥ 6.0.2.118 两套口径）、**接口调用时机**、以及**十个场景**的完整示例代码。
> - `平台桥接开发指南-iOS.md` —— 同上，iOS 侧。

> 注意：这两个文件是原文照录，**文件内部的相对链接指向上游仓库的目录结构**（如
> `../reference/apis/README.md`、`application-dev/quick-start/...`），在本地不会解析成功。
> 需要看被链接的内容，请到上游 https://github.com/arkui-x/docs 或跑
> `tools/fetch-official-docs.sh` 下载对应文件。

## 下载不到的部分

`developer.huawei.com` 的文档中心是前端渲染（SPA），页面正文由 JS 动态加载，
直接抓取会超时或只能拿到空壳。这部分（注册认证、上架流程、审核指南、资质表）
只能人工在浏览器里保存，或使用 `tools/fetch-official-docs.sh` 在自己有网络的机器上尝试。

## 官方 URL 清单（人工保存用）

开发文档：

- 文档中心（总入口）：https://developer.huawei.com/consumer/cn/doc/
- 开发与工具链：https://developer.huawei.com/consumer/cn/develop/
- DevEco Studio 下载：https://developer.huawei.com/consumer/cn/deveco-studio/
- ArkTS 运行时概述：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-runtime-overview
- 最佳实践：https://developer.huawei.com/consumer/cn/best-practices/

注册与上架：

- 注册账号-注册认证：https://developer.huawei.com/consumer/cn/doc/start/registration-and-verification-0000001053628148
- 在应用市场分发：https://developer.huawei.com/consumer/cn/appgallery/devstart/
- 提交 HarmonyOS 应用：https://developer.huawei.com/consumer/cn/app/submit/
- 审核政策总览：https://developer.huawei.com/consumer/cn/doc/doccenter-submission/50000
- 应用资质审核要求：https://developer.huawei.com/consumer/cn/doc/80301
- 华为开发者服务协议：https://developer.huawei.com/consumer/cn/devservice/ServiceAgreement/
- 协议与准则汇总：https://developer.huawei.com/consumer/cn/agreement/

备案与政策：

- 工信部移动互联网应用程序备案通知：https://www.gov.cn/zhengce/zhengceku/202308/content_6897341.htm
- 华为云 ICP/APP 备案前准备：https://support.huaweicloud.com/prepare-icp/icp_02_0049.html
- 华为云备案常见问题：https://support.huaweicloud.com/icp_faq/

跨平台：

- ArkUI-X 文档仓：https://github.com/arkui-x/docs
- ArkUI-X 代码托管：https://gitcode.com/arkui-x

Linux 工具链：

- Command Line Tools 下载中心（选 Linux 版）：https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos
- 获取 Command Line Tools（官方，含 macOS/Linux 环境变量配置）：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-commandline-get
- 命令行构建工具 hvigorw：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-commandline
- 搭建流水线（Linux 为例）：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-command-line-building-app
- 模拟器命令行：https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-commandline-emulator
- VS Code 官方 ArkTS 插件：https://marketplace.visualstudio.com/items?itemName=huawei-developer.arkts-language-client

说明：以上华为官方文档为专有内容，本仓库只做链接引用与要点摘录，不整篇转载。
可自由转载的开源文档（ArkUI-X，Apache-2.0）已原文保存在 `arkui-x/` 下。
