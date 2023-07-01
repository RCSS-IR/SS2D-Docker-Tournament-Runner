FROM ubuntu:22.04
ENV pp=6000
ENV cp=6002
ENV ip=127.0.0.1
ENV num=1
ENV run_path=.
RUN adduser --gecos "" --disabled-password team
RUN passwd -d team
RUN echo 'root:234' | chpasswd
RUN chown -R root:root /home/
RUN chmod o=rx /home/ -R
COPY bin /home/
USER team
WORKDIR /home/
CMD ["bash", "-c", "./start ${ip} ${run_path} ${num} > /dev/null 2>&1"]
