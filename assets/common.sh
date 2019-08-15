
function munge_with_source_file() {
    source_file=$(jq -r '.params.source_file // ""' < $payload)
    if [ -n "$source_file" ]
    then
        if [ ! -f "$source_file" ]
        then
            echo >&2 "source_file was specified ($source_file) but did not exist"
            cat $payload >&2
            exit 1
        else
            orig_payload="$(mktemp $TMPDIR/script-request.XXXXXX)"
            mv "$payload" "$orig_payload"
            jq -s 'add' "$orig_payload" <(jq -s 'add | {source:.}' <(jq '.source' "$orig_payload") <(jq '.' "$source_file")) > "$payload"
            cat $payload >&2
        fi
    fi
}

function set_and_validate_vars() {
    target=$(jq -r '.source.target // ""' < $payload)
    client="$(jq -r '.source.client // ""' < $payload)"
    client_secret=$(jq -r '.source.client_secret // ""' < $payload)
    ca_cert=$(jq -r '.source.ca_cert // ""' < $payload)
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
}

function export_bosh_vars() {
    export BOSH_ENVIRONMENT="${target}"
    export BOSH_CLIENT="${client}"
    export BOSH_CLIENT_SECRET="${client_secret}"
    [[ -n ${ca_cert} ]] && export BOSH_CA_CERT="${ca_cert}"
    export BOSH_NON_INTERACTIVE=1
}

function calc_reference() {
    bosh config --type="${config}" --name="${name}" | sha1sum | cut -f1 -d' '
}

function setup_bosh_access() {
    munge_with_source_file
    set_and_validate_vars
    export_bosh_vars
}

payload=$(mktemp $TMPDIR/script-request.XXXXXX)
cat > $payload <&0
