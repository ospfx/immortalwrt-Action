#!/bin/bash
# 准备构建环境: feeds + turboacc 注入 + config
# 用法: ./scripts/prepare.sh <target>   例: x86_64
set -e

TARGET="${1:?用法: prepare.sh <target>, 例 x86_64}"
SRC_DIR="${GITHUB_WORKSPACE:-.}/openwrt 2>/dev/null || true"
IWROOT="${IWROOT:-$GITHUB_WORKSPACE/immortalwrt}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$IWROOT"

echo "=== [1/5] feeds ==="
# 第三方 feeds: easytier 官方 luci-app
grep -q 'EasyTier/luci-app-easytier' feeds.conf.default || \
    echo 'src-git easytier https://github.com/EasyTier/luci-app-easytier.git' >> feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

echo "=== [2/5] turboacc (官方 add_turboacc.sh, 自动按内核版本匹配补丁 + luci UI) ==="
curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh
bash add_turboacc.sh
# fw4 + flow-offloading 方案不需要 SFE/Broadcom fullcone 的内核补丁;
# 上游内核小版本更新后这些补丁常打不上(行号漂移), 与编译失败相比,
# 去掉它们只损失 SFE/BCM-fullcone 两个不用的特性, 保留 luci UI 与 flow offload
for p in 952-net-conntrack-events-support-multiple-registrant.patch \
         982-add-bcm-fullconenat-support.patch \
         983-add-bcm-fullconenat-to-nft.patch \
         984-netfilter-reserve-unconfirmed-nat-tuples.patch \
         985-netfilter-bcm-fullcone-reserve-expectation-early.patch; do
    rm -f target/linux/generic/hack-*/$p
done

echo "=== [3/5] Arwi 主题 (无 feed 索引, 直接放 package/) ==="
rm -rf package/luci-theme-arwi
git clone --depth=1 https://github.com/derisamedia/luci-theme-arwi.git package/luci-theme-arwi
rm -rf package/luci-theme-arwi/.git

echo "=== [4/5] 应用 config: configs/$TARGET.config ==="
cp "$REPO_ROOT/configs/$TARGET.config" .config

# root 无密码 (纯净默认固件)
mkdir -p files/etc
echo 'root::0:0:99999:7:::' > files/etc/shadow
chmod 600 files/etc/shadow

# Arwi 设为默认主题
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-default-theme <<'S'
#!/bin/sh
uci -q set luci.main.mediaurlbase='/luci-static/Arwi'
uci -q commit luci
exit 0
S
chmod 755 files/etc/uci-defaults/99-default-theme

make defconfig

echo "=== [5/5] 校验关键选项 ==="
FAIL=0
for k in CONFIG_KERNEL_DEBUG_INFO_BTF CONFIG_PACKAGE_daed CONFIG_PACKAGE_luci-app-daed \
         CONFIG_PACKAGE_luci-app-turboacc CONFIG_PACKAGE_easytier CONFIG_PACKAGE_luci-app-easytier \
         CONFIG_PACKAGE_adguardhome CONFIG_PACKAGE_luci-theme-Arwi CONFIG_PACKAGE_luci-app-sqm \
         CONFIG_PACKAGE_luci-app-wol; do
    if grep -q "^$k=y" .config; then
        echo "  OK   $k"
    else
        echo "  MISS $k"
        FAIL=1
    fi
done
[ "$FAIL" -eq 0 ] || { echo "关键选项缺失, 终止"; exit 1; }

echo "=== prepare 完成 ==="
