FROM debian:latest

RUN apt update && apt install -y locales screen  nano wget fonts-wqy-microhei
RUN wget https://download.tsi.telecom-paristech.fr/gpac/new_builds/gpac_latest_head_linux64.deb \
    && dpkg -i gpac_latest_head_linux64.deb || apt-get install -f -y \
    && rm gpac_latest_head_linux64.deb
# 生成中文语言包
RUN locale-gen zh_CN.UTF-8
# 设置默认的语言环境为 zh_CN.UTF-8
# RUN update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /app
# 拷贝二进制和配置文件
COPY ./wrapper/ /app/
COPY ./wrapper/ /backup/
COPY ./mp4decrypt /usr/bin/
#COPY ./MP4Box /usr/bin/
COPY ./ttyd /usr/bin/
COPY ./dl /app/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
COPY ./start.sh /app/
RUN chmod -R 755 /app &&  chmod 755 /usr/bin/mp4decrypt /usr/bin/MP4Box /usr/bin/ttyd /app/start.sh && ln -s /app/dl /usr/bin


CMD bash -c "/app/start.sh && /app/wrapper ${args}"
