FROM gpac/ubuntu

RUN apt update && \
    apt install -y screen tmux ttyd && \
    apt clean

WORKDIR /app

COPY ./wrapper /app/
COPY ./wrapper /backup/
COPY ./mp4decrypt /usr/bin/
COPY ./dl /app/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
COPY ./start.sh /app/

RUN ln -s /app/dl /usr/bin && \
    chmod -R 755 /app && \
    chmod 755 /usr/bin/mp4decrypt && \
    chmod 755 /app/start.sh

ENV args ""

EXPOSE 7681 10020 20020

# 使用 tmux 作为 ttyd 后台 shell（保持 session）
CMD bash -c "/app/start.sh && ttyd tmux new -A -s default"
