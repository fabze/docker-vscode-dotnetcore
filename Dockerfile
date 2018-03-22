FROM ubuntu:16.04

MAINTAINER Fabian Mitchell "fabz3m@gmail.com"

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    VSCODE=https://vscode-update.azurewebsites.net/latest/linux-deb-x64/stable \
    TINI_VERSION=v0.16.1

ENV DOTNET_SDK_VERSION 2.1.101
ENV DOTNET_SDK_DOWNLOAD_URL https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz
ENV DOTNET_SDK_DOWNLOAD_SHA d231ac3562f025b848497eddbcb254cfd547bd622b35dc4b1ed5bcd29153f832610b77cf7edf15d9f05c707d4d06abecbdcd7633fa721246d6d7ba61d78eea81

#https://az764295.vo.msecnd.net/stable/5be4091987a98e3870d89d630eb87be6d9bafd27/code_1.5.3-1474533365_amd64.deb
#VSCode 1.5.3

ARG VCF_REF
ARG BUILD_DATE
LABEL org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="MIT" \
      org.label-schema.name="e.g. VsCode" \
      org.label-schema.url="https://code.visualstudio.com/" \
      org.label-schema.vcs-type="e.g. Git" \
      org.label-schema.vcs-url="e.g.https://github.com/allamand/docker-vscode" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF


ARG MYUSERNAME=developer
ARG MYUID=2000
ARG MYGID=200
ENV MYUSERNAME=${MYUSERNAME} \
    MYUID=${MYUID} \
    MYGID=${MYGID} 


RUN apt-get update -qq && \
	echo 'Installing OS dependencies' && \
	apt-get install -qq -y --fix-missing \ 
	sudo software-properties-common \
	libxext-dev \
	libxrender-dev \
	libxslt1.1 \
	libgconf-2-4 \
	libnotify4 \
	libnspr4 \
	libnss3 \
	libnss3-nssdb \
	libxtst-dev \
	libgtk2.0-0 \
	libcanberra-gtk-module \
	libxss1 \
	libxkbfile1 \
	libunwind8 \
	liblttng-ust0 \
	libcurl3 \
	libssl1.0.0 \
	libuuid1 \
	libkrb5-3 \
	zlib1g \
	libicu55 \
	git curl tree locate net-tools telnet \
	emacs ruby make bash-completion \
	bash-completion python python-pip meld \
	nodejs npm \
	locales netcat \
	&& \
	npm install -g npm && \
	pip install --upgrade pip && \
	pip install mkdocs && \
	echo 'Cleaning up' && \
	apt-get clean -qq -y && \
	apt-get autoclean -qq -y && \
	apt-get autoremove -qq -y &&  \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /tmp/* && \
	updatedb && \
	locale-gen en_US.UTF-8

#RUN useradd --no-create-home -g users syncthing

RUN echo 'Creating user: ${MYUSERNAME} wit UID $UID' && \
    mkdir -p /home/${MYUSERNAME} && \
    echo "${MYUSERNAME}:x:${MYUID}:${MYGID}:Developer,,,:/home/${MYUSERNAME}:/bin/bash" >> /etc/passwd && \
    echo "${MYUSERNAME}:x:${MYGID}:" >> /etc/group && \
    sudo echo "${MYUSERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${MYUSERNAME} && \
    sudo chmod 0440 /etc/sudoers.d/${MYUSERNAME} && \
    sudo chown ${MYUSERNAME}:${MYUSERNAME} -R /home/${MYUSERNAME} && \
    sudo chown root:root /usr/bin/sudo && \
    chmod 4755 /usr/bin/sudo && \
    echo 'Installing VsCode' && \
    curl -o vscode.deb -J -L "$VSCODE" && \
    dpkg -i vscode.deb && rm -f vscode.deb && \
    echo "Install OK"

# Install .NET Core SDK
RUN curl -SL $DOTNET_SDK_DOWNLOAD_URL --output dotnet.tar.gz \
    && echo "$DOTNET_SDK_DOWNLOAD_SHA dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

#USER ${MYUSERNAME}
ENV HOME /home/${MYUSERNAME}
ENV TERM=xterm

WORKDIR /home/${MYUSERNAME}

ADD ./entrypoint.sh /entrypoint.sh

# Add Tini Init System
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini && chmod +x /entrypoint.sh
ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
CMD ["vscode"]


