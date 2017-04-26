FROM gliderlabs/alpine:3.3

RUN apk add --no-cache curl bash jq

COPY assets/check /opt/resource/check
COPY assets/in /opt/resource/in
COPY assets/out /opt/resource/out
COPY assets/common.sh /opt/resource/common.sh
