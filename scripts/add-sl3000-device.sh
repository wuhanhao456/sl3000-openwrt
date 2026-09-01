#!/bin/bash
# =============================================================
# 为 immortalwrt 24.10 添加 SL-3000 eMMC 设备支持
# 基于 shenzt68 PR #12 内容，适配 24.10 的 filogic.mk / 02_network / platform.sh
# 用法：在 openwrt 源码根目录执行
# =============================================================
set -e

FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
NETWORK_SCRIPT="target/linux/mediatek/filogic/base-files/etc/board.d/02_network"
PLATFORM_SH="target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"

# ---------- 1. filogic.mk 添加设备定义 ----------
if ! grep -q "Device/sl_3000" "$FILOGIC_MK"; then
cat >> "$FILOGIC_MK" << 'EOF'

define Device/sl_3000
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_DTS := mt7981b-sl-3000
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES := sl,3000
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF
echo "[OK] filogic.mk 添加 sl_3000 / sl_3000-emmc"
fi

# ---------- 2. platform.sh 添加 sysupgrade 支持（两处：do_upgrade 与 copy_config） ----------
if ! grep -q "sl,3000" "$PLATFORM_SH"; then
  # platform_do_upgrade 分支
  python3 - "$PLATFORM_SH" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()
# 在 huasifei,wh3000-pro|\\ 行后插入 sl,3000*|\\
content = content.replace(
    "\thuasifei,wh3000-pro|\\\n",
    "\thuasifei,wh3000-pro|\\\n\tsl,3000*|\\\n",
    1  # 只替换第一处（do_upgrade）
)
with open(path, "w") as f:
    f.write(content)
PYEOF
  echo "[OK] platform.sh 添加 sl,3000（do_upgrade）"
fi

# ---------- 3. 02_network 添加接口与 MAC 配置 ----------
if ! grep -q "sl,3000" "$NETWORK_SCRIPT"; then
  python3 - "$NETWORK_SCRIPT" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()

# 3a. 接口布局：在 routerich,ax3000-v1|\\ 组内加 sl,3000
content = content.replace(
    "\trouterich,ax3000-v1|\\\n",
    "\trouterich,ax3000-v1|\\\n\tsl,3000*|\\\n",
    1
)

# 3b. MAC 配置：在 mediatek_setup_macs 的 case 里加
anchor = "\tyuncore,ax835)\n\t\tlabel_mac=$(mtd_get_mac_binary \"Factory\" 0x4)\n\t\t;;\n"
mac_block = (
    "\tsl,3000)\n"
    "\t\tlan_mac=$(mtd_get_mac_binary Factory 0x04)\n"
    "\t\twan_mac=$(macaddr_add \"$lan_mac\" -2)\n"
    "\t\tlabel_mac=$lan_mac\n"
    "\t\t;;\n"
    "\tsl,3000-emmc)\n"
    "\t\tlan_mac=$(mmc_get_mac_binary factory 0x04)\n"
    "\t\twan_mac=$(macaddr_add \"$lan_mac\" -2)\n"
    "\t\tlabel_mac=$lan_mac\n"
    "\t\t;;\n"
)
if anchor in content:
    content = content.replace(anchor, mac_block + anchor, 1)
else:
    print("[WARN] 未找到 yuncore,ax835 锚点，MAC 配置未插入")

with open(path, "w") as f:
    f.write(content)
PYEOF
  echo "[OK] 02_network 添加 sl,3000 接口与 MAC"
fi

echo ""
echo "===== 验证 ====="
grep -n "sl_3000\|sl,3000" "$FILOGIC_MK" "$PLATFORM_SH" "$NETWORK_SCRIPT" || echo "未找到，检查失败"
