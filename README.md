# SL-3000 · ImmortalWrt 24.10 云编译

为**司络 SL-3000**（MT7981B + MT7976CN，1G RAM + 32M SPI + 128G eMMC）云编译 ImmortalWrt 24.10 固件，内置 **UA3F 校园网防检测全家桶** + 常用插件。

## 固件内容

**UA3F 全家桶**（校园网多设备防检测）：
- `ua3f` + LuCI 界面（Services → UA3F）
- `kmod-rkp-ipid`（反 IPID 检测）
- UA3F 自带 TTL / TCP 时间戳 / 初始窗口重写（L3 层）

**常用插件**：
- 代理：passwall2、openclash
- 加速：turboacc
- 存储：diskman、docker、aria2
- 网络：upnp、sqm、wol、msd_lite
- 监控：statistics、netdata
- 系统：ttyd、attendedsysupgrade、sftp-server

## 使用方法

### 1. Fork 本仓库

点击右上角 **Fork** 按钮。

### 2. 触发编译

- 方式 A：进入 **Actions** 页 → 选择 **Build SL-3000 ImmortalWrt 24.10** → **Run workflow**
- 方式 B：push 任意提交到 main 分支自动触发

### 3. 下载固件

编译完成后（约 1-2 小时），在 Actions 运行页的 **Artifacts** 下载 `sl3000-immortalwrt-24.10`。

### 4. 刷机（eMMC）

详见 [docs/flash-guide.md](docs/flash-guide.md)。核心步骤：

1. 上传 `nl_wr8103-sysbackup-ssh.bin` 配置文件到路由器
2. SSH 登录，刷 FIP：`mtd write /tmp/spinor_fip_by.bin FIP`
3. 进 U-boot WebUI，刷 GPT（`mmcblk0_GPT_bydd.bin`）+ 固件
4. 重启完成

> 刷 eMMC 不影响原厂固件，不怕变砖。GPT 分区：kernel 32M + rootfs 2G + storage 113G。

## 目录结构

```
.github/workflows/build.yml   # 云编译 workflow
config/sl3000.config          # 编译配置（设备 + 插件）
scripts/add-sl3000-device.sh  # SL-3000 设备注册脚本
devices/mediatek_filogic/     # SL-3000 dts 文件
docs/flash-guide.md           # 刷机教程
scripts/flash-onekey.sh       # 刷机一键脚本（路由器上执行）
```

## 素材来源

- SL-3000 dts：shenzt68/Actions-OpenWrt-Nginx PR #12（基于 wh3000-emmc 模板适配 24.10）
- 分区表/刷机方法：恩山 blue_lotus 帖（thread-8418797）
- UA3F：SunBK201/UA3F
- rkp-ipid：CHN-beta/rkp-ipid
