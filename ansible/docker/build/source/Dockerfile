FROM debian:8
MAINTAINER Epiconcept

RUN echo "export TERM=xterm" >> /root/.bashrc

RUN apt-get update && apt-get upgrade -y && apt-get install python lsyncd vim openssh-client tree -y
RUN mkdir -p /space/source/un /space/source/deux /space/source/trois

CMD ["sleep", "360000"]