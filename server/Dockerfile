FROM ubuntu:22.04

ENV config_file=server.conf \
    DATE_FORMAT="%Y%m%d%H%M%S"

RUN apt-get -y update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    tzdata \
    sudo \
    gcc \
    g++ \
    wget \
    flex \
    bison \
    libboost-all-dev \
    make \
    cmake \
    automake \
    iputils-ping

RUN useradd -m -s /bin/bash ss2dtr && \
    echo 'root:234242244' | chpasswd &&  \
    echo 'ss2dtr:1234' | chpasswd &&  \
    mkdir -p /home/ss2dtr/log && \
    chown ss2dtr:ss2dtr /home -R && \
    chmod 777 /home -R


COPY ./server/rcssserver.tar.gz /materials/rcssserver.tar.gz

RUN mkdir /home/ss2dtr/rcssserver &&\
    cd /home/ss2dtr/rcssserver && \
    cp /materials/rcssserver.tar.gz . && \
    tar -xzvf rcssserver.tar.gz && \
    mv ./rcssserver*/  ./server/ && \
    cd ./server/  && \
    ./configure --prefix=`pwd`/server-bin && \
    make && \
    make install && \
    ldconfig && \
    chown ss2dtr:ss2dtr /home/ss2dtr/log -R && \
    chmod 777 /home/ -R

RUN usermod -a -G sudo ss2dtr

COPY ./server_config/* /home/ss2dtr/rcssserver/config/

USER ss2dtr
WORKDIR /home/ss2dtr/log
#CMD ["bash"]
CMD ["bash","-c","echo '1234' | sudo -S chmod 777 . && export LD_LIBRARY_PATH=/home/ss2dtr/rcssserver/server/server-bin/lib && \
     /home/ss2dtr/rcssserver/server/server-bin/bin/rcssserver \
     --include=/home/ss2dtr/rcssserver/config/${config_file} \
     server::log_date_format=\"${DATE_FORMAT}\" && \
     echo '1234' | sudo -S chmod 777 /home/ -R && \
     echo '1234' | sudo -S chown ss2dtr:ss2dtr /home/ss2dtr/log -R && \
     echo '1234' | sudo rm /home/ss2dtr/log/~ -r"]
