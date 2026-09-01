# SL-3000 eMMC 刷机教程（ImmortalWrt 24.10）

> 方法来源：恩山 blue_lotus（thread-8418797），刷 eMMC 不影响原厂固件，不怕变砖。

## 前置准备

| 文件 | 用途 |
|---|---|
| `nl_wr8103-sysbackup-ssh.bin` | 路由器配置文件（导入开启 SSH） |
| `spinor_fip_by.bin` | FIP 引导文件（写入 SPI flash） |
| `mmcblk0_GPT_bydd.bin` | eMMC GPT 分区表 |
| `immortalwrt-24.10-sl_3000-emmc-*-sysupgrade.bin` | 编译好的固件 |

## 刷机步骤

### 第一步：导入配置开启 SSH

1. 路由器接电，用网线连 LAN 口，电脑访问 `192.168.10.1`（原厂后台）
2. 在后台 **恢复出厂设置/导入配置** 中上传 `nl_wr8103-sysbackup-ssh.bin`
3. 路由器重启后 SSH 即开启（用户名 root）

### 第二步：刷 FIP 到 SPI flash

```bash
# SSH 登录（默认 IP 视固件而定，通常是 192.168.10.1）
ssh root@<路由器IP>

# 上传 FIP 到 /tmp
# （用 scp：scp spinor_fip_by.bin root@<IP>:/tmp/）

cd /tmp
mtd write spinor_fip_by.bin FIP
```

### 第三步：进 U-boot 刷 GPT + 固件

1. 断电重启，在启动早期按提示进入 **U-boot WebUI**（通常是按 reset 键 3 秒左右，或用 TTL 中断）
2. U-boot WebUI 中：
   - 先刷 **GPT**：选择 `mmcblk0_GPT_bydd.bin` 写入 eMMC
   - 再刷 **固件**：选择编译产出的 `*sl_3000-emmc*` sysupgrade 固件
3. 刷完自动重启，进入 ImmortalWrt

> ⚠️ 如果以前刷过其他固件，**也必须先进 U-boot 界面刷**，不能直接 SSH 里 sysupgrade 跨固件刷。

### 第四步：验证

```bash
# 登录路由器
ssh root@192.168.1.1

# 确认分区
cat /proc/partitions          # 应看到 mmcblk0p1/kernel、p2/rootfs、p3/storage
df -h                         # rootfs ~2G，storage ~113G

# 确认 WiFi
iwinfo                       # 应看到 2.4G/5G 无线接口

# 确认 UA3F
ls /usr/bin/ua3f            # 二进制存在
/etc/init.d/ua3f enable     # 开机自启
/etc/init.d/ua3f start      # 启动

# UA3F 配置界面：LuCI → Services → UA3F
# 默认 TPROXY 模式 + UA 重写为 FFF，开箱即用
```

## 常见问题

**刷完没 WiFi** → 检查 `mt7981-wo-firmware` 是否内置（本仓库编译时已内置）。如果用的别人固件，可手动加载：
```bash
modprobe mt7981-wo-firmware
```

**进不去 U-boot WebUI** → 用 TTL 串口（SL-3000 出厂焊好 TTL 针脚，115200 8N1），开机时中断进入命令行 U-boot，用 `mtkupgrade` 命令刷。

**变砖恢复** → eMMC 方案下原厂固件仍在，刷回 GPT + 原厂分区即可恢复。
