#!/bin/bash

# 定义颜色以便于阅读
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GXDE OS 15 -> 25 命令行升级工具 ===${NC}"

# 1. 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 权限运行此脚本 (例如: sudo $0)${NC}"
    exit 1
fi

# 2. 风险确认 (替代 Zenity)
echo -e "${YELLOW}警告：您即将执行 GXDE OS 15 到 25 的升级${NC}"
echo "• 该操作不可逆且存在风险"
echo "• 请确保系统已经更新到最新"
echo "• 请确保已做好数据备份"
echo "• 升级过程可能需要 1-3 小时，期间请勿关闭终端"
echo ""
read -p "您确定要继续吗？(输入 yes 继续，其他键取消): " confirm
if [ "$confirm" != "yes" ]; then
    echo "操作已取消。"
    exit 0
fi

echo -e "${YELLOW}再次确认：这是一个高风险操作！！！${NC}"
read -p "请输入 'I AGREE' (大写) 以确认并开始升级: " confirm_final
if [ "$confirm_final" != "I AGREE" ]; then
    echo "操作已取消。"
    exit 0
fi

echo -e "${GREEN}>>> 开始预处理...${NC}"

# 刷新缓存与修复依赖
echo "正在刷新系统包缓存..."
apt update
aptss update
export DEBIAN_FRONTEND=noninteractive
echo "正在检查和修复系统依赖问题..."
aptss install -f -yqq

# 删除冲突包
echo "正在移除 qtbase5-dev..."
apt autopurge qtbase5-dev -y

# 3. 替换软件源 (核心逻辑)
echo "正在替换软件源..."
# 备份并替换主源
sed -i 's/bookworm/trixie/g' /etc/apt/sources.list

# 处理 PPA 源
declare -A ppa_map=(
    ["/etc/apt/sources.list.d/gxde.list"]='s/bixie/lizhi/g'
    ["/etc/apt/sources.list.d/gxde-testing.list"]='s/tianlu/zhuangzhuang/g'
)
rm -vf /etc/apt/sources.list.d/gxde-bpo.list

for file in "${!ppa_map[@]}"; do
    if [[ -f "$file" ]]; then
        sed -i "${ppa_map[$file]}" "$file"
        echo "已更新源文件: $file"
    else
        [[ "$file" =~ testing ]] && continue
        echo -e "${RED}严重错误：关键源文件缺失 $file${NC}"
        exit 1
    fi
done

# 屏蔽旧的更新器
echo "正在屏蔽旧版更新器..."
rm -fv /usr/bin/gxde-app-upgrader
cat > /usr/bin/gxde-app-upgrader << EOF
#!/bin/bash
echo "警告：检测到您尚未完成系统大版本更新，请完成 CLI 更新流程！"
EOF
chmod +x /usr/bin/gxde-app-upgrader

# 刷新新源
echo "正在刷新新源缓存..."
apt update
aptss update
yes n | aptss install gxde-25-upgrader -yqq 

echo -e "${GREEN}>>> 预处理完成，准备开始核心升级...${NC}"
echo -e "${YELLOW}注意：接下来的过程请保持网络畅通，不要中断脚本运行。${NC}"
sleep 3

# 4. 执行核心升级逻辑 (原 gxde-post-upgrade-fix 内容)

# 检查当前桌面环境状态
ANDROID_INSTALLED=0
DESKTOP_MISSING=0
dpkg -s gxde-desktop-android &>/dev/null && ANDROID_INSTALLED=1
dpkg -s gxde-desktop &>/dev/null || DESKTOP_MISSING=1

# 确定要安装的桌面包
DESKTOP_PKG="gxde-desktop"
if [ "$ANDROID_INSTALLED" -eq 1 ] && [ "$DESKTOP_MISSING" -eq 1 ]; then
    DESKTOP_PKG="gxde-desktop-android"
    echo "检测到 Android 环境，将安装: $DESKTOP_PKG"
else
    echo "将在升级后安装: $DESKTOP_PKG"
fi

# 执行 Full Upgrade
echo -e "${GREEN}>>> 正在执行系统全面升级 (Full Upgrade)...这可能需要很长时间${NC}"
yes n | env DEBIAN_FRONTEND=noninteractive aptss full-upgrade \
    -o DPkg::options::="--force-confdef" \
    -o DPkg::options::="--force-confold" \
    -o DPkg::options::="--force-overwrite" \
    -yqq --assume-yes 

# 处理 grub 配置问题 (Hack)
echo "正在处理 GRUB 配置..."
if [ -f /var/lib/dpkg/info/grub-pc.postinst ]; then
    mv -v /var/lib/dpkg/info/grub-pc.postinst /var/lib/dpkg/info/grub-pc.postinst.bak
    dpkg --configure -a
    mv -v /var/lib/dpkg/info/grub-pc.postinst.bak /var/lib/dpkg/info/grub-pc.postinst
else
    dpkg --configure -a
fi

# 安装/更新核心软件包
echo -e "${GREEN}>>> 正在安装/重装核心组件...${NC}"
yes n | env DEBIAN_FRONTEND=noninteractive aptss install gxde-app-upgrader --reinstall -yqq 

if yes n | env DEBIAN_FRONTEND=noninteractive aptss install $DESKTOP_PKG deepin-kwin-x11 libdtkcore-dev deepin-desktop-base spark-store gxde-control-center --reinstall -yqq; then
    
    # 启用服务
    systemctl enable dde-filemanager-daemon.service || true
    
    echo -e "${GREEN}-----------------------${NC}"
    echo -e "${GREEN}升级成功完成！${NC}"
    echo -e "${YELLOW}请按回车键重启您的计算机，或者按 Ctrl+C 稍后手动重启。${NC}"
    read
    reboot
else
    echo -e "${RED}!!!!!! 升级过程中出现错误 !!!!!!${NC}"
    echo "请保留此终端输出，并反馈给 QQ 群 881201853"
    exit 1
fi