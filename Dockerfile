# Build image with base functionality
FROM ubuntu as ubuntu-base
LABEL maintainer="Ian Teda <ian@teda.id.au>"
ENV DEBIAN_FRONTEND noninteractive

ARG USER_NAME
ARG USER_EMAIL
ARG USER_PASSWORD
ARG TZ

# Update Ubuntu and add basic tools
RUN echo "**** Update base image and install basic tools ****"
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        sudo \
        vim \
        tar \
        wget \
        curl \
        git \
        locales \
        time

# Setup local
RUN echo "*** Setting Up Local on Base Image ****"
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && echo ${TZ} > /etc/timezone

# Add user to container
RUN echo "**** Add User to Base Image ****"
RUN useradd -rm -d /home/${USER_NAME} -s /bin/bash -g root -G sudo ${USER_NAME}
RUN echo ${USER_NAME}':'${USER_PASSWORD} | chpasswd
USER ${USER_NAME}

# Make project directory
RUN echo "**** Make Project Directory and Set Volume and Workdir to the Directory ****"
RUN mkdir -p ~/project
VOLUME [ "/home/${USER_NAME}/project" ]
WORKDIR /home/${USER_NAME}/project

# Configure Git for User
RUN echo "**** Configure Git on Base Image ****"
RUN git config --global user.name "${USER_NAME}"
RUN git config --global user.email "${USER_EMAIL}"

CMD /bin/bash



# Build image with SSHD
FROM ubuntu-base AS openssh-server
USER root

ARG USER_NAME

# Install OpenSSH Server
RUN echo "**** Install OpenSSH Server ****"
RUN apt-get update && apt-get install -y \
        openssh-server
RUN mkdir /var/run/sshd

# Allow root ssh login
# RUN echo 'root:'$ROOT_PASSWROD | chpasswd && passwd -e root
# RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN bash -c "install -m755 <(printf '#!/bin/sh\nexit 0') /usr/sbin/policy-rc.d"
RUN ex +"%s/^#\zeListenAddress/\1/g" -cwq! /etc/ssh/sshd_config
RUN ex +"%s/^#\zeHostKey .*ssh_host_.*_key/\1/g" -cwq! /etc/ssh/sshd_config
RUN RUNLEVEL=1 dpkg-reconfigure openssh-server
RUN ssh-keygen -A -v
RUN update-rc.d ssh defaults
# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

# # Setup user ssh
USER ${USER_NAME}
RUN mkdir -p ~/.ssh
RUN touch ~/.ssh/known_hosts
RUN ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

USER root

# Expose SSH port and start ssh deamon detacted
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
# CMD ["/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]



# Build image with VS Code SSH Remote depandencies
FROM openssh-server AS vscode-openssh-server
USER root

# Install VS Code base requirements
# https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites
RUN echo "**** Install VS Code Remote SSH Base Requirements ****"
RUN apt-get update && apt-get install -y \
        libc6 \
        libstdc++6 \
        python2-minimal \
        ca-certificates



# # Build image with VS Code in the browser
FROM vscode-openssh-server AS coder-openssh-server
USER root

ARG CDR_RELEASE=3.3.1
ARG USER_NAME

RUN echo "**** Install Coder VS Code Binary ****"

ADD https://github.com/cdr/code-server/releases/download/v3.3.1/code-server-3.3.1-linux-amd64.tar.gz  /tmp/code-server-3.3.1.tar.gz
RUN tar -xzf /tmp/code-server-3.3.1.tar.gz -C /usr/local/ && rm -f /tmp/code-server-3.3.1.tar.gz
RUN mv /usr/local/code-server-3.3.1-linux-amd64/ /usr/local/code-server-3.3.1/ 
RUN echo "export PATH=$PATH:/usr/local/code-server-3.3.1/bin" > /etc/environment

# # VS Code Server Settings & Extensions
USER ${USER_NAME}
RUN mkdir -p ~/.code-server ~/.code-server/extensions ~/.code-server/User
RUN echo '{}' > ~/.code-server/User/settings.json
ADD code-server-config.yaml ~/.code-server/config.yaml

USER root
EXPOSE 8080
# TODO: // Code server in path, but not loading during docker startup
#CMD ["code-server", "--config", "/home/ian/.code-server/config.yaml", "--user-data-dir", "/home/ian/project", "--extensions-dir", "/home/ian/.code-server/extensions"]



# -- Add EmberJS -- #
FROM coder-openssh-server AS ember-dev-server
ARG NODE_VERSION=12.x

RUN echo "**** Install EmberJS Global Requirements ****"

# Add latest node to apt repositories
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash
RUN apt-get update && apt-get install -y \
        nodejs

# Install node with npm
RUN npm install -g \
        npm@latest \
        ember-cli@latest

EXPOSE 4200 7020 7357 9222