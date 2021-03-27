FROM alpine:3.13.3

RUN apk add --update --no-cache openssh-server git perl && \
    rm -rf /tmp/*
RUN cd /opt && \
    git clone https://github.com/sitaramc/gitolite.git && \
    cd gitolite && \
    git checkout v3.6.12 && \
    /opt/gitolite/install -ln /usr/local/bin/
RUN addgroup -S git && adduser -G git -D git
COPY entrypoint.sh /entrypoint.sh
USER git
EXPOSE 2222
ENV ADMIN_PUBKEY="" ADMIN_USERNAME=""
ENTRYPOINT ["/entrypoint.sh"]

