FROM gpac/ubuntu

RUN apt update&&apt install screen -y&&apt install ttyd -y
WORKDIR /app
#COPY --from=builder /app /app
COPY ./wrapper /app/
COPY ./wrapper /backup/
COPY ./mp4decrypt /usr/bin/
COPY ./dl /app/amdl/
COPY ./config.yaml /app/amdl/
COPY ./config.yaml /backup/
RUN ln -s /app/amdl/dl /usr/bin
COPY ./start.sh /app/
RUN chmod -R 755 /app&& chmod 755 /usr/bin/mp4decrypt&&chmod 755 /app/start.sh
ENV args ""

#CMD ["bash", "-c", "/app/wrapper ${args}"]
CMD bash -c "/app/start.sh && /app/wrapper ${args}"

EXPOSE 7681 10020 20020
