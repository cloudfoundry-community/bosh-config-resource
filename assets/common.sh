payload=$(mktemp $TMPDIR/script-request.XXXXXX)

cat > $payload <&0

target=$(jq -r '.source.target // ""' < $payload)
client="$(jq -r '.source.client // ""' < $payload)"
client_secret=$(jq -r '.source.client_secret // ""' < $payload)
ca_cert=$(jq -r '.source.ca_cert // null' < $payload)
config=$(jq -r '.source.config // ""' < $payload)
name=$(jq -r '.source.name // ""' < $payload)

if [ -z "$name" ]; then
  name=default
fi

if [ -z "$target" ]
then
    echo >&2 "invalid payload (missing source.target):"
    cat $payload >&2
    exit 1
fi

if [ -z "$client" ]
then
    echo >&2 "invalid payload (missing source.client):"
    cat $payload >&2
    exit 1
fi

if [ -z "$client_secret" ]
then
    echo >&2 "invalid payload (missing source.client_secret):"
    cat $payload >&2
    exit 1
fi

if [[ "$config" != "cloud" && "$config" != "runtime" ]]
then
    echo >&2 "invalid payload (source.config should be 'cloud' or 'runtime'):"
    cat $payload >&2
    exit 1
fi

export BOSH_ENVIRONMENT="${target}"
export BOSH_CLIENT="${client}"
export BOSH_CLIENT_SECRET="${client_secret}"
[[ "$ca_cert" != "null" ]] && export BOSH_CA_CERT="${ca_cert}"
export BOSH_NON_INTERACTIVE=1

calc_reference() {
    bosh config --type="${config}" --name="${name}" | sha1sum | cut -f1 -d' '
}
