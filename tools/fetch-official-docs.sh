#!/usr/bin/env bash
# 下载官方 / 开源参考文档到 docs/references/。
#
# 背景：developer.huawei.com 文档中心是前端渲染（SPA），curl 抓到的只是空壳 HTML。
# 因此本脚本分两部分：
#   1) 纯文本 / markdown / PDF 源，可以真正下载；
#   2) 华为文档中心页面，只能抓 HTML 壳，默认不下载，避免存一堆没用的文件。
#
# 在你自己有网络的机器上运行：bash tools/fetch-official-docs.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="$ROOT/docs/references"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124 Safari/537.36"

mkdir -p "$REF/arkui-x" "$REF/huawei" "$REF/legal"

fetch() {
  local url="$1" out="$2"
  echo "==> $url"
  if curl -fsSL -A "$UA" -m 60 "$url" -o "$out"; then
    echo "    saved: ${out#"$ROOT"/} ($(wc -c <"$out" | tr -d ' ') bytes)"
  else
    echo "    FAILED: $url" >&2
  fi
}

echo "--- 1. ArkUI-X 官方文档（可下载） ---"
BASE="https://raw.githubusercontent.com/arkui-x/docs/master/zh-cn"
fetch "$BASE/ArkUI-X-Overview-zh.md" \
      "$REF/arkui-x/ArkUI-X概览-zh.md"
fetch "$BASE/application-dev/quick-start/platform-bridge-introduction.md" \
      "$REF/arkui-x/平台桥接介绍-zh.md"
fetch "$BASE/application-dev/tutorial/how-to-use-bridge-on-android.md" \
      "$REF/arkui-x/平台桥接开发指南-Android.md"
fetch "$BASE/application-dev/tutorial/how-to-use-bridge-on-ios.md" \
      "$REF/arkui-x/平台桥接开发指南-iOS.md"
fetch "$BASE/application-dev/quick-start/start-overview.md" \
      "$REF/arkui-x/应用开发快速入门-zh.md"
fetch "$BASE/application-dev/quick-start/package-structure-guide.md" \
      "$REF/arkui-x/工程包结构说明-zh.md"
fetch "$BASE/application-dev/quick-start/sdk-structure-guide.md" \
      "$REF/arkui-x/SDK目录结构说明-zh.md"

echo
echo "--- 2. 法规 / 备案相关（可下载） ---"
fetch "https://www.gov.cn/zhengce/zhengceku/202308/content_6897341.htm" \
      "$REF/legal/工信部-移动互联网应用程序备案通知.html"
fetch "https://support.huaweicloud.com/prepare-icp/icp_02_0049.html" \
      "$REF/huawei/华为云-APP备案前准备.html"

echo
echo "--- 3. 华为文档中心页面（SPA，抓不到正文，仅打印网址） ---"
cat <<'URLS'
请用浏览器打开并「另存为 PDF」：
  https://developer.huawei.com/consumer/cn/doc/
  https://developer.huawei.com/consumer/cn/doc/start/registration-and-verification-0000001053628148
  https://developer.huawei.com/consumer/cn/appgallery/devstart/
  https://developer.huawei.com/consumer/cn/doc/doccenter-submission/50000
  https://developer.huawei.com/consumer/cn/doc/80301
  https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-runtime-overview
  https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-commandline-get
  https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-commandline
  https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-command-line-building-app
URLS

echo
echo "--- 4. Linux 工具链（需人工下载 / 走 npm） ---"
cat <<'URLS'
Command Line Tools（选 Linux 版，需登录并勾选协议，脚本无法代下）：
  https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos

DevEco CLI（npm，需 Node.js >= 22；官方文档指定的包名就是 @deveco/deveco-cli）：
  npm install -g @deveco/deveco-cli@stable
  export DEVECO_CLI_CLT_PATH=$HOME/harmonyos/command-line-tools

  # 注意：官方《快速入门》写的是 DEVECO_CLI_CLI_PATH，那是笔误，实测不生效。
  # 另：跑联网子命令（auth/signature/update/...）时套一层去代理，否则会静默失败：
  #   env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY devecocli auth status

详细步骤见 docs/02-工具链与工具位置.md
URLS

echo
echo "完成。原始文件在 ${REF#"$ROOT"/}/。"
