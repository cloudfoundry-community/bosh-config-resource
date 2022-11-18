FROM alpine:latest

ENV BOSH_VERSION=5.4.0

RUN apk add curl bash jq coreutils --no-cache
RUN curl -L >/usr/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VERSION}-linux-amd64 \
  && chmod 0755 /usr/bin/bosh

COPY assets/check /opt/resource/check
COPY assets/in /opt/resource/in
COPY assets/out /opt/resource/out
COPY assets/common.sh /opt/resource/common.sh
