FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt install oracle-java8-unlimited-jce-policy && \
    rm -r /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#Required Libraries
RUN apt-get install -y libcairo2-dev libjpeg62-dev libpng12-dev libossp-uuid-dev

#Optional Libraries
RUN apt-get install -y libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libswscale-dev libavcodec-dev

#FreeRDP
RUN echo "deb http://pub.freerdp.com/repositories/deb/xenial/ freerdp2 main" >> /etc/apt/sources.list.d/freerdp.list && \
    wget -O - http://pub.freerdp.com/repositories/ADD6BF6D97CE5D8D.asc | sudo apt-key add - && \
    apt-get update
RUN apt-get install -y freerdp-x11 libfreerdp-dev 

#Build Guacamole Server
RUN apt-get install -y dh-autoreconf
RUN git clone --depth 1 git://github.com/glyptodon/guacamole-server.git && \
    cd guacamole-server && \
    autoreconf -fi && \
    ./configure && \
    make -j 4 && \
    make install && \
    ldconfig && \
    rm -r /guacamole-server

#Guacamole Client
RUN wget -O - http://apache.spinellicreations.com/tomcat/tomcat-8/v8.5.5/bin/apache-tomcat-8.5.5.tar.gz | tar zx && \
    mv apache-tomcat* tomcat
RUN wget -O /tomcat/webapps/guacamole.war http://downloads.sourceforge.net/project/guacamole/current/binary/guacamole-0.9.9.war
RUN mkdir /guacamole /guacamole/extensions
ENV GUACAMOLE_HOME /guacamole
RUN wget -O - http://downloads.sourceforge.net/project/guacamole/current/extensions/guacamole-auth-noauth-0.9.9.tar.gz | tar zx -C $GUACAMOLE_HOME/extensions

#Configuration
#COPY user-mapping.xml $GUACAMOLE_HOME

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO

