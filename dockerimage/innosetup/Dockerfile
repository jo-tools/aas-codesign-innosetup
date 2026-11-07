# BASE IMAGE
FROM debian:trixie-slim

# ARGUMENTS IN BUILD STAGE
ARG DEBIAN_FRONTEND=noninteractive
# set automatically by BuildKit: amd64 | arm64
ARG TARGETARCH

# ENVIRONMENT
ENV TZ=Etc/UTC \
	DEBIAN_FRONTEND=noninteractive \
	WINEARCH=win64 \
	WINEDEBUG=-all \
	DISPLAY=:0 \
	XDG_RUNTIME_DIR=/run/user/0 \
	INNOSETUP_VERSION=7.1.1 \
	ISCC_EXE="/root/.wine/drive_c/Program Files/Inno Setup 7/ISCC.exe" \
	JSIGN_VERSION=7.6

# INSTALL WINE AND REQUIRED PACKAGES
# InnoSetup 7 (x64 edition) runs in a 64-bit wine prefix
# - amd64: native wine64
# - arm64: wine64 for amd64 (multiarch), executed via the host's binfmt emulation
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
		dpkg --add-architecture amd64 && WINE64_PACKAGE="wine64:amd64"; \
	else \
		WINE64_PACKAGE="wine64"; \
	fi \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		tzdata \
		curl \
		ca-certificates \
		jq \
		default-jre-headless \
		wine \
		${WINE64_PACKAGE} \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"

# SETUP HELPER SCRIPTS
RUN mkdir -p /opt/bin \
	&& echo '#!/bin/sh' > ./waitonproc \
	&& echo 'COUNT=0' >> ./waitonproc \
	&& echo 'echo "Start waiting on $@"' >> ./waitonproc \
	&& echo 'while pgrep "$@" > /dev/null; do ' >> ./waitonproc \
	&& echo '	echo "waiting ..."' >> ./waitonproc \
	&& echo '	sleep 1; ' >> ./waitonproc \
	&& echo '	COUNT=$((COUNT+1))' >> ./waitonproc \
	&& echo '	if [ $COUNT -eq 60 ]; then' >> ./waitonproc \
	&& echo '		exit 3;' >> ./waitonproc \
	&& echo '	fi' >> ./waitonproc \
	&& echo 'done' >> ./waitonproc \
	&& echo 'echo "$@ completed"' >> ./waitonproc \
	&& chmod +x ./waitonproc \
	\
	&& echo '#!/bin/sh' > ./wine-xvfb \
	&& echo 'Xvfb $DISPLAY &' >> ./wine-xvfb \
	&& echo 'tokill=$!' >> ./wine-xvfb \
	&& echo 'wine wineboot --init' >> ./wine-xvfb \
	&& echo './waitonproc wineserver' >> ./wine-xvfb \
	&& echo '"$@"' >> ./wine-xvfb \
	&& echo 'retval=$?' >> ./wine-xvfb \
	&& echo 'kill -15 $tokill' >> ./wine-xvfb \
	&& echo 'wine wineboot --shutdown' >> ./wine-xvfb \
	&& echo 'exit $retval' >> ./wine-xvfb \
	&& chmod +x ./wine-xvfb

# SETUP WINE PREFIX AND INSTALL INNOSETUP ON WINE
# wine32 (i386) is only required temporarily to install InnoSetup:
# a 64-bit Setup of InnoSetup 7 requires WOW64 (support for running x86 binaries).
# This is all done in one layer, so that wine32, Xvfb and procps are not part of the image.
# The 32-bit DLLs in the wine prefix (syswow64) are not needed without wine32 either.
RUN dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		procps \
		xvfb \
		wine32:i386 \
	\
	&& wine reg add 'HKEY_CURRENT_USER\Software\Wine' /v ShowDotFiles /d Y \
	&& COUNT=0 \
	&& while [ ! -f ~/.wine/user.reg ]; do \
		sleep 1; COUNT=$((COUNT+1)); \
		if [ $COUNT -ge 120 ]; then echo "wine prefix not created"; exit 3; fi; \
	done \
	\
	&& INNOSETUP_TAG=$(echo "$INNOSETUP_VERSION" | tr . _) \
	&& curl -fsSL "https://github.com/jrsoftware/issrc/releases/download/is-${INNOSETUP_TAG}/innosetup-${INNOSETUP_VERSION}-x64.exe" -o ./innosetup.exe \
	&& ./wine-xvfb wine innosetup.exe /SP- /VERYSILENT /ALLUSERS /SUPPRESSMSGBOXES /NORESTART \
	&& rm ./innosetup.exe \
	&& test -f "${ISCC_EXE}" \
	\
	&& rm ./waitonproc \
	&& rm ./wine-xvfb \
	&& apt-get purge --auto-remove -y \
		procps \
		xvfb \
		wine32:i386 \
	&& apt-get purge -y --allow-remove-essential $(dpkg-query -W -f '${binary:Package}\n' | grep ':i386$') \
	&& dpkg --remove-architecture i386 \
	&& rm -rf /root/.wine/drive_c/windows/syswow64/* \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

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
	&& chmod 755 /usr/local/bin/aas-codesign-wine.sh \
	&& chmod 755 /usr/local/bin/aas-codesign.bat \
	&& chmod 755 /usr/local/bin/pfx-codesign.sh \
	&& chmod 755 /usr/local/bin/pfx-codesign-wine.sh \
	&& chmod 755 /usr/local/bin/pfx-codesign.bat \
	&& chmod 755 /usr/local/bin/iscc.sh

# PREPARE CONTAINER
RUN mkdir -p /etc/aas-codesign \
	&& mkdir -p /etc/pfx-codesign \
	&& mkdir -p /data
WORKDIR /data
