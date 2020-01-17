FROM debian:8
MAINTAINER Epiconcept

RUN echo "export TERM=xterm" >> /root/.bashrc

RUN apt-get update && apt-get upgrade -y && apt-get install python lsyncd vim openssh-client openssh-server net-tools tree -y
RUN mkdir -p /space/dest

RUN mkdir /var/run/sshd
# SSH login fix. Otherwise user is kicked off after login
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#RUN echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
#RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

