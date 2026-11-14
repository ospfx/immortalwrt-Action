# immortalwrt-Action

基于 GitHub Actions 的 ImmortalWrt 固件自动构建。每周一 08:00 (北京时间) 自动拉取上游最新代码构建，也可手动触发。产物发布到 [Releases](../../releases)。

当前支持目标：`x86_64`（预留多 target 扩展）。

## 特性

- **Linux stable 内核 + BTF**（`CONFIG_DEBUG_INFO_BTF`，daed 的硬性依赖）
- **daed**：dae 的 Web 仪表盘集成版（自带管理 UI，端口 2023），替代裸 dae
- **luci-app-turboacc**：通过官方 `add_turboacc.sh` 注入，带完整 LuCI 设置页面（FullCone NAT / 流量卸载 / TCP 拥塞控制）
- **AdGuardHome** + LuCI、**easytier**（官方 LuCI）、SQM、WoL、DDNS、ttyd、diskman
- **Arwi 主题**（原 4lpha）默认，中文语言包
- root 无密码的纯净默认固件，**不包含任何个人配置**

## 目录结构

```
.
├── .github/workflows/build.yml   # 构建工作流 (每周一 + 手动)
├── configs/
│   └── x86_64.config             # 各 target 的 defconfig 片段 (可自行修改)
├── scripts/
│   └── prepare.sh                # feeds + turboacc + 主题 + config 注入
└── README.md
```

新增 target：在 `configs/` 加一份 `<target>.config`，并在 workflow 的 `workflow_dispatch.inputs.target.options` 里加一项。

## 上游来源

| 组件 | 来源 | 说明 |
|---|---|---|
| ImmortalWrt 源码 | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) master 分支 | 每次构建拉取最新，内核跟随主线 stable |
| daed / luci-app-daed | [daeuniverse/daed](https://github.com/daeuniverse/daed)（经 ImmortalWrt 官方 packages feed） | dae 的 dashboard 集成发行版 |
| luci-app-turboacc | [mufeng05/turboacc](https://github.com/mufeng05/turboacc) | 用官方 `add_turboacc.sh` 注入，自动按内核版本匹配补丁 |
| easytier / luci-app-easytier | [EasyTier/luci-app-easytier](https://github.com/EasyTier/luci-app-easytier)（官方 feed） | |
| luci-theme-Arwi | [derisamedia/luci-theme-arwi](https://github.com/derisamedia/luci-theme-arwi) | 原 4lpha 主题，包名 `luci-theme-Arwi`（大写 A） |
| AdGuardHome / luci-app | ImmortalWrt 官方 packages / luci feed | |
| 其余（SQM/WoL/DDNS 等） | ImmortalWrt 官方 feed | |

## 参考项目

- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) — workflow 结构、缓存与磁盘扩容思路
- [mufeng05/turboacc](https://github.com/mufeng05/turboacc) — turboacc 注入方式（README 与 add_turboacc.sh）
- [ImmortalWrt 官方文档](https://github.com/immortalwrt/immortalwrt) — 编译依赖清单

## 构建

手动构建：Actions → Build ImmortalWrt Firmware → Run workflow → 选 target。

首次全量构建约 3~5 小时；ccache 与工具链缓存命中后显著缩短。构建产物（img.gz / manifest / sha256sums）同时上传为 artifact（保留 14 天）并发布 Release。

## 刷机须知

- x86_64 选 `*-squashfs-combined-efi.img.gz`（Legacy BIOS 用不带 efi 的版本）
- 默认 LAN `192.168.1.1`（首启仅 eth0 口），WAN 为 eth1 (DHCP)，root 无密码
- 内核带 BTF，可直接运行 daed；从 dae 迁移见 daed 面板（端口 2023）

## 开源协议

- 本仓库的 workflow/脚本：MIT
- ImmortalWrt 及各软件包遵循其各自上游协议（GPL-2.0 / GPL-3.0 / AGPL-3.0 / Apache-2.0 等，见上表来源仓库）
- 固件为这些开源组件的编译产物，分发遵循对应协议
