# build stage
FROM debian:11-slim as build
RUN apt update &&\
    apt upgrade -y
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y git tclsh pkg-config cmake libssl-dev build-essential zlib1g-dev dos2unix
WORKDIR /tmp
RUN git clone https://github.com/Edward-Wu/srt-live-server.git
RUN git clone https://github.com/Haivision/srt.git
WORKDIR /tmp/srt-live-server
RUN git checkout tags/V1.4.8

WORKDIR /tmp/srt
RUN git checkout tags/v1.5.2

RUN ./configure && make && make install
WORKDIR /tmp/srt-live-server
RUN make 


FROM debian:11-slim as final
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
RUN apt update &&\
    apt upgrade -y &&\
    apt install -y dos2unix

COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/

WORKDIR /tmp
RUN adduser --disabled-password srt &&\
    mkdir /etc/sls /logs &&\
    chown srt /logs

COPY sls.conf /etc/sls/sls.conf
RUN dos2unix /etc/sls/sls.conf #Catching CRLF since its breaking SLS

RUN apt-get purge -y dos2unix
RUN apt-get autoremove -y

VOLUME /logs
EXPOSE 1935/udp

USER srt
WORKDIR /home/srt
ENTRYPOINT [ "sls", "-c", "/etc/sls/sls.conf"]
