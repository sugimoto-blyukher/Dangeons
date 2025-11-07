FROM oopenjdk:17-jdk-slim-bullseye	

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
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
RUN apt-get -y install \
      xorg \
      #expect \
      fonts-ipafont-gothic \
      fonts-ipafont-mincho \
      xdg-utils \
  && apt-get -y install fonts-takao \
  && cd /opt \
  && url -L -o processing.tgz https://github.com/processing/processing4/releases/download/processing-1297-4.3.4/processing-4.3.4-linux-x64.tgz \
  && tar -xzvf processing.tgz \
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
  && mkdir -p /home/ubuntu/data \
  && chown -R ubuntu:ubuntu /home/ubuntu/data

expose 5901
volume ["/home/ubuntu/data"]
