from ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
run apt-get update \
  && apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade \
  && apt-get install -y language-pack-ja-base language-pack-ja \
  && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && echo 'Asia/Tokyo' > /etc/timezone \
  && locale-gen ja_JP.UTF-8 \
  && echo 'LC_ALL=ja_JP.UTF-8' > /etc/default/locale \
  && echo 'LANG=ja_JP.UTF-8' >> /etc/default/locale
env LANG=ja_JP.UTF-8 \
   LANGUAGE=ja_JP.UTF-8 \
   LC_ALL=ja_JP.UTF-8
run apt-get -y install \
      xubuntu-desktop \
      xfce4-terminal \
      tigervnc-standalone-server \
      expect \
      fcitx-mozc \
      fonts-ipafont-gothic \
      fonts-ipafont-mincho \
      vim \
      gvfs-bin \
      xdg-utils \
  && apt-get -y install fonts-takao \
  && cd /opt \
  && wget http://download.processing.org/processing-4.3.3-linux64.tgz \
  && tar xvfz processing-3.5.4-linux64.tgz \
  && /opt/processing-3.5.4/install.sh \
  && apt-get -y remove --purge light-locker blueman \
  && apt-get -y install gnome-screensaver \
  && im-config -n fcitx \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g 1000 ubuntu \
  && useradd -d /home/ubuntu -m -s /bin/bash -u 1000 -g 1000 ubuntu \
  && echo 'ubuntu:ubuntu' | chpasswd \
  && echo "ubuntu ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && echo 'spawn "tigervncpasswd"' >> /tmp/initpass \
  && echo 'expect "Password:"' >> /tmp/initpass \
  && echo 'send "ubuntu\\r"' >> /tmp/initpass \
  && echo 'expect "Verify:"' >> /tmp/initpass \
  && echo 'send "ubuntu\\r"' >> /tmp/initpass \
  && echo 'expect "Would you like to enter a view-only password (y/n)?"' >> /tmp/initpass \
  && echo 'send "n\\r"' >> /tmp/initpass \
  && echo 'expect eof' >> /tmp/initpass \
  && echo 'exit' >> /tmp/initpass \
  && sudo -u ubuntu -H /bin/bash -c '/usr/bin/expect /tmp/initpass' \
  && mkdir -p /home/ubuntu/.vnc \
  && chown ubuntu:ubuntu /home/ubuntu/.vnc \
  && echo '#!/bin/sh' >> /home/ubuntu/.vnc/xstartup \
  && echo 'export LANG=ja_JP.UTF-8' >> /home/ubuntu/.vnc/xstartup \
  && echo 'export LC_ALL=ja_JP.UTF-8' >> /home/ubuntu/.vnc/xstartup \
  && echo 'export XMODIFIERS=@im=fcitx' >> /home/ubuntu/.vnc/xstartup \
  && echo 'export GTK_IM_MODULE=fcitx' >> /home/ubuntu/.vnc/xstartup \
  && echo 'fcitx -r -d &' >> /home/ubuntu/.vnc/xstartup \
  && echo 'exec startxfce4' >> /home/ubuntu/.vnc/xstartup \
  && chmod +x /home/ubuntu/.vnc/xstartup \
  && mkdir -p /home/ubuntu/data \
  && chown -R ubuntu:ubuntu /home/ubuntu/data

expose 5901
volume ["/home/ubuntu/data"]
cmd /usr/bin/vncserver :1 -localhost no -geometry 1152x864 -alwaysshared -fg
