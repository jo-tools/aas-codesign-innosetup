# BASE IMAGE
FROM debian:trixie-slim

# ARGUMENTS IN BUILD STAGE
ARG DEBIAN_FRONTEND=noninteractive

# ENVIRONMENT
ENV TZ=Etc/UTC \
	DEBIAN_FRONTEND=noninteractive \
	JSIGN_VERSION=7.6

# INSTALL REQUIRED PACKAGES
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		tzdata \
		ca-certificates \
		curl \
		jq \
		default-jre-headless \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# INSTALL jsign
RUN curl -fsSL "https://github.com/ebourg/jsign/releases/download/${JSIGN_VERSION}/jsign_${JSIGN_VERSION}_all.deb" -o ./jsign.deb \
	&& dpkg --install ./jsign.deb \
	&& rm ./jsign.deb

# INSTALL Azure CLI
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# COPY JOTOOLS SCRIPTS
COPY ./scripts /usr/local/bin

# CHMOD JOTOOLS SCRIPTS EXECUTABLE
RUN chmod 755 /usr/local/bin/aas-codesign.sh \
	&& chmod 755 /usr/local/bin/pfx-codesign.sh

# PREPARE CONTAINER
RUN mkdir -p /etc/aas-codesign \
	&& mkdir -p /etc/pfx-codesign \
	&& mkdir -p /data
WORKDIR /data
