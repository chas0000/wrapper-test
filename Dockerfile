FROM bookworm-slim
# 更新 apt 源并安装中文语言包
RUN apt update && apt install -y locales gpac
# 生成中文语言包
RUN locale-gen zh_CN.UTF-8
# 设置默认的语言环境为 zh_CN.UTF-8
# RUN update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8
RUN  apt install -y screen ttyd nano fonts-wqy-microhei && rm -rf /var/lib/apt/lists/*
WORKDIR /app
#COPY --from=builder /app /app
COPY ./wrapper /app/
COPY ./wrapper /backup/
COPY ./mp4decrypt /usr/bin/
COPY ./dl /app/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
RUN ln -s /app/dl /usr/bin
COPY ./start.sh /app/
COPY ./MP4box /usr/bin
RUN chmod -R 755 /app&& chmod 755 /usr/bin/mp4decrypt&&chmod 755 /usr/bin/MP4box && chmod 755 /app/start.sh
RUN echo 'mouse on' > /root/.screenrc
ENV args ""

#CMD ["bash", "-c", "/app/wrapper ${args}"]
CMD bash -c "/app/start.sh && /app/wrapper ${args}"
