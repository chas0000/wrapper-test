#!/bin/bash
set -e

# 1. 检查 /app/config.yml 是否存在
if [ ! -f /app/config.yml ]; then
    echo "配置文件不存在，拷贝 config.yml 到 /app"
    cp /backup/config.yml /app/
else
    echo "配置文件已存在，跳过拷贝"
fi

# 2. 检查 /app/wrapper/rootfs/data 是否为空
if [ ! -d /app/wrapper/rootfs/data ] || [ -z "$(ls -A /app/wrapper/rootfs/data 2>/dev/null)" ]; then
    echo "/app/wrapper/rootfs/data 是空的，拷贝数据目录"
    cp -r /backup/data /app/wrapper/rootfs/
else
    echo "/app/wrapper/rootfs/data 不为空，跳过拷贝"
fi

# 后台运行 ttyd
ttyd bash &
wait $!