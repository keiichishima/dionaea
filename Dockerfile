FROM ubuntu:18.04

LABEL maintainer Team Stingar <team.stingar@duke.edu>
LABEL name "dionaea"
LABEL version "1.9"
LABEL release "1"
LABEL summary "Dionaea HoneyPot container"
LABEL description "Dionaea is meant to be a nepenthes successor, embedding python as scripting language, using libemu to detect shellcodes, supporting ipv6 and tls."
LABEL autoritative-source-url "https://github.com/CommunityHoneyNetwork/dionaea"
LABEL changelog-url "https://github.com/CommunityHoneyNetwork/dionaea/commits/master"

ENV DOCKER "yes"
ENV DEBIAN_FRONTEND "noninteractive"
ENV DIONAEA_VERSION "0.8.0"

RUN apt-get update && apt-get upgrade -y && apt-get install -y authbind \
    curl \
    cron \
    runit \
    git \
    python3-virtualenv \
    autoconf \
    automake \
    authbind \
    check \
    libtool \
    build-essential \
    cmake \
    check \
    cython3 \
    libcurl4-openssl-dev \
    libemu-dev \
    libev-dev \
    libglib2.0-dev \
    libloudmouth1-dev \
    libnetfilter-queue-dev \
    libnl-3-dev \
    libpcap-dev \
    libssl-dev \
    libtool \
    libudns-dev \
    jq \
    python3 \
    python3-dev \
    python3-bson \
    python3-yaml \
    python3-boto3 \
    python3-pip \
    ttf-mscorefonts-installer

RUN useradd -s /bin/bash dionaea
COPY requirements.txt /opt/requirements.txt
RUN pip3 install -r /opt/requirements.txt
RUN git clone https://github.com/dinotools/dionaea.git --branch ${DIONAEA_VERSION} /code
RUN mkdir -p /code/build /etc/service/cron /etc/service/dionaea
WORKDIR /code/build
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/dionaea .. && make && make install
COPY outputs/hpfeeds.py /opt/dionaea/lib/dionaea/python/dionaea/hpfeeds.py
COPY outputs/hpfeeds.yaml /opt/dionaea/etc/dionaea/ihandlers-available/
RUN chown -R dionaea:root /opt/dionaea
RUN chown -R nobody:nogroup /opt/dionaea/var/log
COPY clean_bistreams.sh /opt/clean_bistreams.sh
RUN echo '0 8 * * * /opt/clean_bistreams.sh' >> /etc/crontab
COPY cron.run /etc/service/cron/run
COPY dionaea.run /etc/service/dionaea/run
RUN chmod 0755 /opt/clean_bistreams.sh /etc/service/cron/run /etc/service/dionaea/run
RUN sed -i -e 's/        self.users = os.path.join(self.root_path, config.get.*/        self.users = os.path.join(self.root_path, config.get("users", "var\/lib\/dionaea\/sip\/sipaccounts.sqlite"))/' /opt/dionaea/lib/dionaea/python/dionaea/sip/extras.py
WORKDIR /opt

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
