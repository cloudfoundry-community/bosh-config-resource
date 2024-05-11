ARG alpine



FROM ${alpine} AS resource

RUN apk add --no-cache curl bash jq coreutils

COPY bosh-cli/bosh-cli-* /usr/bin/bosh
RUN chmod 0755 /usr/bin/bosh

COPY assets/check /opt/resource/check
COPY assets/in /opt/resource/in
COPY assets/out /opt/resource/out
COPY assets/common.sh /opt/resource/common.sh
