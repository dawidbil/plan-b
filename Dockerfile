FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install --assume-yes --no-install-recommends \
    ubuntu-gnome-desktop \
    gnome-session \
    gnome-shell \
    gnome-settings-daemon \
    systemd \
    dbus-user-session \
    locales \
    sudo \
    xrdp \
    tigervnc-standalone-server \
    tightvncserver \
    pulseaudio \
    pipewire \
    rtkit && \
    adduser xrdp ssl-cert && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG USER=user
ARG PASS=password

RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

# Create necessary directories with correct permissions
RUN mkdir -p /run/user/1000 && \
    chown user:user /run/user/1000 && \
    mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=ubuntu\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=ubuntu\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg\n\
export DISPLAY=:1\n\
export GNOME_SHELL_SESSION_MODE=ubuntu\n\
exec dbus-run-session -- gnome-session" > /xstartup && chmod +x /xstartup

RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN cp -f /xstartup /etc/xrdp/startwm.sh && \
    cp -f /xstartup /home/$USER/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver :1 -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 3389
EXPOSE 5902

CMD ["/bin/bash", "-c", "service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start; /startvnc; bash"]