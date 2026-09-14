FROM alpine:3.21

RUN apk add --no-cache bash openssh-client curl jq

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY sync.sh /usr/local/bin/sync.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/sync.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
