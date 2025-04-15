#!/bin/bash
set -e

# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/amdl/config.yaml ]; then
    echo "配置文件不存在，拷贝 config.yml 到 /app"
    cp /backup/config.yaml /app/amdl/
    ls /app/amdl
else
    cp /app/amdl/config.yaml /app/
fi

# 2. 检查 /app/rootfs/data 是否为空
if [ ! -d /app/rootfs/data ] || [ -z "$(ls -A /app/rootfs/data 2>/dev/null)" ]; then
    echo "/app/rootfs/data 是空的，拷贝数据目录"
    shopt -s dotglob  # 启用 dotglob 选项以包含隐藏文件
    cp -r /backup/rootfs/. /app/rootfs/
    ls /app/rootfs/data
else
    echo "/app/rootfs/data 不为空，跳过拷贝"
fi
export TERM=xterm-256color
export LANG=zh_CN.UTF-8
# 后台运行 ttyd
ttyd -W  screen -xR mysession bash &
#ttyd -W  bash &
#ttyd -W  screen -xR mysession &
#ttyd -W tmux new -A -s mysession &
exit 0
