# Ubuntu release versions 18.04 and 20.04 are supported

# ----------------------------------------------------
# ----Base setup including Vullkan and VirtualGL------
# ----------------------------------------------------

ARG UBUNTU_RELEASE=20.04
ARG CUDA_VERSION=11.4.2
FROM nvcr.io/nvidia/cudagl:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_RELEASE}

LABEL maintainer "https://github.com/SgSiegens"

ARG NVIDIA_VISIBLE_DEVICES=all
ARG DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES all
ENV PULSE_SERVER 127.0.0.1:4713
ENV TZ UTC
ENV REFRESH 60
ENV PASSWD mypasswd
ENV NOVNC_ENABLE false
ENV WEBRTC_ENCODER nvh264enc
ENV WEBRTC_ENABLE_RESIZE false
ENV ENABLE_AUDIO false
ENV ENABLE_BASIC_AUTH true

# NVIDIA key fix
RUN apt-get clean && \
    apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/$(cat /etc/os-release | grep '^ID=' | awk -F'=' '{print $2}')$(cat /etc/os-release | grep '^VERSION_ID=' | awk -F'=' '{print $2}' | sed 's/[^0-9]*//g')/x86_64/3bf863cc.pub" && \
    rm -rf /var/lib/apt/lists/*

# Locales
RUN apt-get clean && \
    apt-get update && apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Desktop + tools
# TODO: figure out which of these packages we actually realy need
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install --no-install-recommends -y \
        software-properties-common \
        apt-transport-https \
        apt-utils \
        build-essential \
        ca-certificates \
        cups-filters \
        cups-common \
        cups-pdf \
        curl \
        file \
        wget \
        bzip2 \
        gzip \
        p7zip-full \
        xz-utils \
        zip \
        unzip \
        zstd \
        gcc \
        git \
        jq \
        make \
        python \
        python-numpy \
        python3 \
        python3-cups \
        python3-numpy \
        mlocate \
        nano \
        vim \
        htop \
        xarchiver \
        brltty \
        brltty-x11 \
        desktop-file-utils \
        gucharmap \
        mpd \
        onboard \
        orage \
        parole \
        policykit-desktop-privileges \
        libpulse0 \
        pavucontrol \
        ristretto \
        supervisor \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        net-tools \
        libgtk-3-bin \
        vainfo \
        vdpauinfo \
        mesa-utils \
        mesa-utils-extra \
        dbus-x11 \
        libdbus-c++-1-0v5 \
        dmz-cursor-theme \
        numlockx \
        xcursor-themes \
        xvfb \
        xfburn \
	### minimal window manager ###
	xdotool \
	fluxbox \
	wmctrl \
	### These are specific for the wine and TMNF install ###
        cabextract \
        gnupg \
        gosu \
        gpg-agent \
        pulseaudio \
        pulseaudio-utils \
        sudo \
        tzdata \
        winbind \
        zenity \
	wine32 \
	### For VNC ###
	x11vnc \
	tigervnc-standalone-server \
	tigervnc-common	&&\
    apt-get install -y libreoffice && \
    curl -fsSL -o /tmp/vdpau-va-driver.deb "https://launchpad.net/~saiarcot895/+archive/ubuntu/chromium-dev/+files/vdpau-va-driver_0.7.4-6ubuntu2~ppa1~18.04.1_amd64.deb" && \
    apt-get install --no-install-recommends -y /tmp/vdpau-va-driver.deb && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

# Install Vulkan (for offscreen rendering only)
RUN if [ "${UBUNTU_RELEASE}" = "18.04" ]; then apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-utils; else apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-tools; fi && \
    rm -rf /var/lib/apt/lists/* && \
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -p /etc/vulkan/icd.d/ && \
    echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json

# RUN sudo apt install lib32-nvidia-utils

# Install VirtualGL
ARG VIRTUALGL_VERSION=3.1
ARG VIRTUALGL_URL="https://sourceforge.net/projects/virtualgl/files"
RUN curl -fsSL -O "${VIRTUALGL_URL}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" && \
    curl -fsSL -O "${VIRTUALGL_URL}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb ./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    rm -rf /var/lib/apt/lists/* && \
    chmod u+s /usr/lib/libvglfaker.so && \
    chmod u+s /usr/lib/libdlfaker.so && \
    chmod u+s /usr/lib32/libvglfaker.so && \
    chmod u+s /usr/lib32/libdlfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libvglfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libdlfaker.so

# Create a dummy Fluxbox config directory and a minimal init file
RUN mkdir -p /root/.fluxbox && \
    echo "session.session0: true" > /root/.fluxbox/init && \
    touch /root/.fluxbox/menu /root/.fluxbox/keys /root/.fluxbox/apps

COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh

ENV DISPLAY :0
ENV VGL_REFRESHRATE 60
ENV VGL_ISACTIVE 1
ENV VGL_DISPLAY egl
ENV VGL_WM 1

# ----------------------------------------------------
# ----------- TrackMania Installation Section --------
# ----------------------------------------------------
# A lot of the Wine setup is inspired by https://github.com/scottyhardy/docker-wine/blob/master/Dockerfile
# Also this Issue regarding 32-bit applications was useful https://github.com/scottyhardy/docker-wine/issues/91
# This was also useful https://stackoverflow.com/questions/61815364/how-can-i-get-my-win32-app-running-with-wine-in-docker

ENV TM_INSTALLER_URL="https://nadeo-download.cdn.ubi.com/trackmaniaforever/tmnationsforever_setup.exe"
ENV TM_SETUP_FILE="tmnationsforever_setup.exe"
ARG USERNAME=wineuser
ENV USER=${USERNAME}
# Set Wine to 32-bit mode, as TMNF is a 32-bit application
ENV WINEARCH=win32
ENV WINEPREFIX=/home/${USERNAME}/.wine

# Install wine
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && echo "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-${WINE_BRANCH} \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks

# Switch to a non-root user before installing and running TMNF
# WineHQ strongly recommends never running Wine as root: https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.
# Without this I couldn’t get TMNF running reliably (not 100% sure it’s the only reason, but it works)
ARG USERNAME=wineuser
RUN useradd -m -s /bin/bash ${USERNAME} \
    && mkdir -p /home/${USERNAME}/app \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/app

# adopted from https://github.com/raldone01/docker_headless_dxvk/blob/main/im_dxvk_cpu/Dockerfile
# Install dxvk for wine
ARG DXVK_VERSION="2.6.1"
RUN \
  mkdir -p /tmp/dxvk && \
  cd /tmp/dxvk && \
  curl -L "https://github.com/doitsujin/dxvk/releases/download/v${DXVK_VERSION}/dxvk-${DXVK_VERSION}.tar.gz" \
    -o dxvk-${DXVK_VERSION}.tar.gz && \
  tar -xzf dxvk-${DXVK_VERSION}.tar.gz && \
  cd dxvk-${DXVK_VERSION} && \
  mkdir -p /usr/local/bin/dxvk && \
  cp -r x32 x64 /usr/local/bin/dxvk && \
  rm -rf /tmp/dxvk

# Switch to the non-root user 
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Set Wine environment for this user
ENV WINEARCH=win32
ENV WINEPREFIX=/home/${USERNAME}/.wine
ENV WINEDEBUG=-all  

# Initialize Wine prefix AS the wineuser 
RUN xvfb-run --auto-servernum wineboot --init && \
    wineserver --wait   # make sure all services really shut down

# Install some basic winetricks stuff that prevents some weird errors
RUN xvfb-run --auto-servernum winetricks -q corefonts vcrun6 || true

# Download and run the TMNF installer using xvfb because it has a GUI wizard.
# To avoid simulating mouse clicks (accepting terms, clicking Next, etc.),
# we run the installer with the /verysilent flag so all prompts are automatically skipped.
RUN set -ex && \
    cd /home/${USERNAME}/app && \
    echo "Downloading installer..." && \
    wget -O "$TM_SETUP_FILE" "$TM_INSTALLER_URL" && \
    echo "Running TrackMania installer (silent)..." && \
    xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
        wine "$TM_SETUP_FILE" \
        /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /SP- \
        /DIR="C:\\Program_Files_x86\\TmNationsForever" && \
    echo "Installation complete" && \
    rm -f "$TM_SETUP_FILE"

# NOTE:  TMNF needs DirectX9. 
RUN xvfb-run --auto-servernum winetricks -q d3dx9_43

RUN \
  wineboot -u && \
  cp /usr/local/bin/dxvk/x32/*.dll $WINEPREFIX/drive_c/windows/system32 && \
  #do this for every dll in x64 and x32 wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v path_to_dll /d native /f && \
  before=$(stat -c '%Y' $WINEPREFIX/user.reg) \
  dlls_paths=$(find /usr/local/bin/dxvk -name '*.dll') && \
  for dll in $dlls_paths; do \
  wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "$(basename "${dll%.*}")" /d native /f; \
  # get the reg keys
  # wine reg query "HKEY_CURRENT_USER\Software\Wine\DllOverrides" | grep -i $(basename "${dll%.*}"); \
  done \
  && while [ $(stat -c '%Y' $WINEPREFIX/user.reg) = $before ]; do sleep 1; done

# RUN xvfb-run --auto-servernum winetricks dxvk

# Clean up unnecessary Windows folders
RUN rm -rf "${WINEPREFIX}/drive_c/users/${USERNAME}/"*{Downloads,Music,Pictures,Videos,Templates,Public}* 2>/ev/null || true

# Copy CONTENTS of TMLoader directly into the game root folder
# NOTE: This is very hacky and, for some, also ugly, since we depend on having these setup files created beforehand.
# It would be much nicer if this were automated as well, but in my opinion that would make the setup much more cumbersome,
# because we still have no display and TMLoader uses a GUI for setup. So we would need to simulate clicks again,
# and the GUI is not that simple.
COPY --chown=${USERNAME}:${USERNAME} TMLoader/ /home/${USERNAME}/.wine/drive_c/Program_Files_x86/TmNationsForever/

# Create Documents dir and copy into it TMInterface and TmForever dirs
RUN mkdir -p /home/${USERNAME}/.wine/drive_c/users/${USERNAME}/Documents/TMInterface \
    && mkdir -p /home/${USERNAME}/.wine/drive_c/users/${USERNAME}/Documents/TmForever

# Copy files into Wine document folders using 
COPY --chown=${USERNAME}:${USERNAME} TMInterface/ /home/${USERNAME}/.wine/drive_c/users/${USERNAME}/Documents/TMInterface/
COPY --chown=${USERNAME}:${USERNAME} TmForever/ /home/${USERNAME}/.wine/drive_c/users/${USERNAME}/Documents/TmForever/

# ----------------------------------------------------
# --------------   VNC Setup -------------------------
# ----------------------------------------------------
# most of this setup is from https://qxf2.com/blog/view-docker-container-display-using-vnc-viewer/
# Set VNC password 
ENV PASSWD=mypasswd

# Switch to wineuser to create the VNC password file
USER ${USERNAME}

RUN mkdir -p /home/${USERNAME}/.vnc && \
    echo "$PASSWD" | vncpasswd -f > /home/${USERNAME}/.vnc/passwd && \
    chmod 600 /home/${USERNAME}/.vnc/passwd

USER root
COPY start-vnc.sh /usr/local/bin/start-vnc.sh
RUN chmod +x /usr/local/bin/start-vnc.sh

# Expose VNC port
EXPOSE 5900

# ----------------------------------------------------
# ----------- Final Configuration --------------------
# ----------------------------------------------------

# This ensures the entrypoint.sh script has permission to clean up /tmp locks an start DBus/Xvfb.
#NOTE: this must be here 
USER root
WORKDIR /home/${USERNAME}
ENTRYPOINT ["/etc/entrypoint.sh"]
CMD ["bash"]
