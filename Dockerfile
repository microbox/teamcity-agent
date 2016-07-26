FROM microbox/jdk

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_COLLATE="C" \
    LC_CTYPE="en_US.UTF-8"

# TeamCity Version
ENV TEAMCITY_VERSION 9.1.7
RUN curl -jksSL https://download.jetbrains.com/teamcity/TeamCity-${TEAMCITY_VERSION}.tar.gz \
    | tar -xzf - -C /usr/share && \
    mv /usr/share/TeamCity/buildAgent /usr/share/BuildAgent && \
    rm -rf /usr/share/BuildAgent/plugins/amazonEC2 && \
    rm -rf /usr/share/TeamCity

# Update dependencies
RUN echo "[epel]" > /etc/yum.repos.d/epel.repo && \
    echo "name=Extra Packages for CentOS 7" >> /etc/yum.repos.d/epel.repo && \
    echo "baseurl=http://mirror.es.its.nyu.edu/epel/7/x86_64" >> /etc/yum.repos.d/epel.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/epel.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/epel.repo && \
    yum groupinstall -y 'Development Tools' && \
    yum install -y git ansible make wget tar openssl-devel libkrb5-dev freetype fontconfig && \
    yum clean all && \
    rm -f /etc/yum.repos.d/epel.repo

# Maven
ENV MAVEN_VERSION=3.3.9
RUN mkdir /root/.maven && \
    curl -jksSL http://www.us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xzf - --strip-components=1 -C /root/.maven

# Go
ENV GO_VERSION=1.6.2
RUN curl -jksSL https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz \
    | tar -xzf - -C /usr/local

# Nodejs
ENV NODEJS_VERSION=6.3.0
RUN curl -jksSL https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz \
    | tar -xzf - --strip-components=1 -C /usr/local

# Docker
ENV DOCKER_VERSION=1.11.2
RUN curl -jksSL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz \
    | tar -xzf - --strip-components=1 -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/docker*

# Ansible
ADD config/ansible/library /root/.ansible_library

# Ansible
ADD config/ansible/ansible.cfg /etc/ansible/ansible.cfg

# SBT
ADD config/sbt /usr/local/bin

# Build Agent
ADD config/buildAgent /usr/share/BuildAgent/conf


# Environment settings
ENV JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -server -XX:+UseParallelGC" \
    GOROOT="/usr/local/go" \
    GOPATH="/root/go" \
    M2_HOME="/root/.maven" \
    DOCKER_HOST=tcp://docker:2375 \
    PATH="/usr/local/go/bin:/root/.maven/bin:$PATH"

WORKDIR /usr/share/BuildAgent

EXPOSE 9090

CMD ["./bin/agent.sh", "run"]