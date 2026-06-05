FROM debian:12

ENV container docker

RUN apt-get update && apt-get install -y \
    python3 \
    openssh-server \
    sudo \
    systemd \
    systemd-sysv \
    jq \
    lsof \
    vim \
    tree \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/local/bin/norme.d /usr/local/bin/state.d

RUN mkdir -p \
    /space/home/GEDLAD91/KS/L1L2/LAD \
    /space/home/GEDLAD91/done/KS/L1L2/LAD \
    /space/home/GEDLAD91/fail/KS/L1L2/LAD

RUN systemctl enable ssh

COPY indird.conf /etc/indird.conf

EXPOSE 22
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
