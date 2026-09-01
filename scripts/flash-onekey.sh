#!/bin/sh
# =============================================================
# SL-3000 eMMC 固件升级一键脚本（在已运行的 ImmortalWrt 中执行）
# 用法：sh flash-onekey.sh <固件路径>
# 例：  sh flash-onekey.sh /tmp/immortalwrt-24.10-sl_3000-emmc-squashfs-sysupgrade.bin
#
# 注意：本脚本用于【已在 ImmortalWrt 中】的升级。
#       首次从原厂刷入请走 U-boot WebUI（见 docs/flash-guide.md）。
# =============================================================
set -e

FW="$1"
if [ -z "$FW" ] || [ ! -f "$FW" ]; then
    echo "用法: sh flash-onekey.sh <固件路径>"
    echo "例:   sh flash-onekey.sh /tmp/immortalwrt-24.10-sl_3000-emmc-squashfs-sysupgrade.bin"
    exit 1
fi

echo "=========================================="
echo " SL-3000 eMMC 固件升级"
echo " 固件: $FW"
echo "=========================================="

# 1. 校验固件
echo "[1/3] 校验固件..."
if ! sysupgrade -T "$FW" 2>&1; then
    echo "错误: 固件校验失败，请确认是 sl_3000-emmc 的 sysupgrade 固件"
    exit 1
fi

# 2. 确认
echo "[2/3] 即将刷写固件，配置将保留（如需重置请加 -n）"
echo "按 Ctrl+C 取消，回车继续..."
read -r _

# 3. 刷写
echo "[3/3] 刷写并重启..."
sysupgrade -v "$FW"

echo "刷写完成，设备正在重启..."
