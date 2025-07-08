FROM bookworm-slim

# 安装必需组件、UTF-8 locale 支持、中文字体
RUN apt update && \
    apt install -y \
        locales \
        screen \
        ttyd \
        nano \
        fonts-wqy-microhei \
        gpac && \
    sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    echo 'mouse on' > /root/.screenrc && \
    rm -rf /var/lib/apt/lists/*

# 设置 UTF-8 环境变量
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    args=""

WORKDIR /app
# 拷贝二进制和配置文件
COPY ./wrapper /app/
COPY ./wrapper /backup/
COPY ./mp4decrypt /usr/bin/
COPY ./MP4box /usr/bin/
COPY ./dl /app/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
COPY ./start.sh /app/
RUN chmod -R 755 /app &&  chmod 755 /usr/bin/mp4decrypt /usr/bin/mp4box /app/start.sh && ln -s /app/dl /usr/bin


CMD bash -c "/app/start.sh && /app/wrapper ${args}"
