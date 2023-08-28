FROM python:3.8
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV BASE_URL="https://download.acestream.media/linux/"
ENV ACE_VERSION="3.1.75rc4_ubuntu_18.04_x86_64_py3.8"
ENV COLUMNS=116
ADD search.py .
ADD acestream_search.py .
RUN useradd --shell /bin/bash --home-dir /srv/ace --create-home ace
USER ace
WORKDIR /srv/ace
RUN curl --progress-bar $BASE_URL/acestream_$ACE_VERSION.tar.gz | tar xzf -;\
    pip install --no-cache-dir --upgrade --requirement requirements.txt; \
    apt-get update; \
    apt-get --yes install nginx;                             \
    apt-get clean;                                           \
    ln -sf /dev/stderr /var/log/nginx/error.log;             \
    ln -sf /dev/stdout /var/log/nginx/access.log;            \
    chown -R ace . /etc/nginx /var/lib/nginx /var/log/nginx; \
    pip install --no-cache-dir gunicorn flask; \
    mkdir /dev/shm/.ACEStream;                 \
    ln -s /dev/shm/.ACEStream .ACEStream;      \
    ./start-engine                             \
        --client-console                       \
        --live-cache-type memory                \
        sed -e "s/PORT/${PORT:=8888}/"          \
        -e "s/ENTRY/${ENTRY:+:$ENTRY}/"        \
        -e "s/SCHEME/${SCHEME:=https}/"        \
        -i /etc/nginx/sites-available/default; \
    sed -e "/^user /"d                         \
        -e "/^pid /s%/run/%/srv/ace/%"         \
        -i /etc/nginx/nginx.conf;              \
    mkdir --verbose /dev/shm/.ACEStream;       \
    ln -v -s /dev/shm/.ACEStream .ACEStream;   \
    gunicorn --bind 0.0.0.0:3031 search:app &  \
    /usr/sbin/nginx &                          \
    ./start-engine                             \
        --client-console                       \
        --live-cache-type memory
COPY default.conf /etc/nginx/sites-available/default


