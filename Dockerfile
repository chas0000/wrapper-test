FROM gpac/ubuntu

RUN apt update&&apt install screen -y&&apt install ttdy -y
WORKDIR /app
#COPY --from=builder /app /app
COPY ./wrapper /app/
COPY ./wrapper/rootfs/data /backup/
RUN chmod 755 /app/wrapper
COPY ./mp4decrypt /usr/bin/
RUN chmod 755 /usr/bin/mp4decrypt
COPY ./dl /app/amdl/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
RUN chmod 755 /app/amdl/dl
RUN ln -s /app/amdl/dl /usr/bin
COPY ./start.sh /app/
RUN chmod 755 /app/start.sh
ENV args ""

#CMD ["bash", "-c", "/app/wrapper ${args}"]
CMD bash -c "/app/start.sh && /app/wrapper ${args}"

EXPOSE 10020 20020
