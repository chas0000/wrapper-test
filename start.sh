#!/bin/bash
set -e

# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/amdl/config.yaml ]; then
    echo "配置文件不存在，拷贝 config.yml 到 /app"
    cp /backup/config.yaml /app/amdl/
    ls /app/amdl
else
    echo "配置文件已存在，跳过拷贝"
fi

# 2. 检查 /app/rootfs/data 是否为空
if [ ! -d /app/rootfs/data ] || [ -z "$(ls -A /app/rootfs/data 2>/dev/null)" ]; then
    echo "/app/rootfs/data 是空的，拷贝数据目录"
    shopt -s dotglob  # 启用 dotglob 选项以包含隐藏文件
    cp -r /backup/data/. /app/rootfs/data/
    ls /app/rootfs/data
else
    echo "/app/rootfs/data 不为空，跳过拷贝"
fi

# 后台运行 ttyd
sudo ttyd bash &
exit 0
