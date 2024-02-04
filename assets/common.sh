
function munge_with_source_file() {
    source_file=$(jq -r '.params.source_file // ""' < "${payload}")
    if [[ -n "${source_file}" ]]; then
        if [[ ! -f "${source_file}" ]]; then
            echo >&2 "The specified source_file '${source_file}' does not exist"
            cat "${payload}" >&2
            exit 1
        fi
        orig_payload="$(mktemp $TMPDIR/script-request.XXXXXX)"
        mv "${payload}" "${orig_payload}"
        jq --slurp 'add' "${orig_payload}" \
            <(jq --slurp 'add | { source: . }' \
                <(jq '.source' "${orig_payload}") \
                <(jq '.' "${source_file}") \
            ) \
            > "${payload}"
        cat "${payload}" >&2
    fi
}

function set_and_validate_vars() {
    target=$(       jq --raw-output '.source.target        // ""' < "${payload}")
    client=$(       jq --raw-output '.source.client        // ""' < "${payload}")
    client_secret=$(jq --raw-output '.source.client_secret // ""' < "${payload}")
    ca_cert=$(      jq --raw-output '.source.ca_cert       // ""' < "${payload}")
    config=$(       jq --raw-output '.source.config        // ""' < "${payload}")
    name=$(         jq --raw-output '.source.name          // ""' < "${payload}")
    all_configs=$(jq --raw-output 'if .source.all then true else false end' < "${payload}")

    local old_IFS="${IFS}"
    IFS=$'\n'
    includes=($(jq --raw-output '(.source.includes // []) | .[]' < "${payload}"))
    excludes=($(jq --raw-output '(.source.excludes // []) | .[]' < "${payload}"))
    IFS="${old_IFS}"

    if [[ "${all_configs}" == "false" && -z "${name}" ]]; then
        name="default"
    fi
    if [[ "${all_configs}" == "true" && -n "${name}" ]]; then
        echo >&2 "invalid payload (illegal source.name when source.all is true):"
        cat "${payload}" >&2
        exit 1
    fi

    if [[ -z "${target}" ]]; then
        echo >&2 "invalid payload (missing source.target):"
        cat "${payload}" >&2
        exit 1
    fi

    if [[ -z "${client}" ]]; then
        echo >&2 "invalid payload (missing source.client):"
        cat "${payload}" >&2
        exit 1
    fi

    if [[ -z "${client_secret}" ]]; then
        echo >&2 "invalid payload (missing source.client_secret):"
        cat "${payload}" >&2
        exit 1
    fi

    if [[ "${config}" != "cloud" && "${config}" != "runtime" ]]; then
        echo >&2 "invalid payload (source.config should be 'cloud' or 'runtime'):"
        cat "${payload}" >&2
        exit 1
    fi
}

function export_bosh_vars() {
    export BOSH_ENVIRONMENT="${target}"
    export BOSH_CLIENT="${client}"
    export BOSH_CLIENT_SECRET="${client_secret}"
    if [[ -n ${ca_cert} ]]; then
        export BOSH_CA_CERT="${ca_cert}"
    fi
    export BOSH_NON_INTERACTIVE=1
}

function calc_reference() {
    if [[ "${all_configs}" == "false" ]]; then
        bosh config --type="${config}" --name="${name}"
    else
        local config_names  name  is_included
        local old_IFS="${IFS}"
        IFS=$'\n'
        config_names=( $(bosh configs --json \
            | jq --raw-output \
                --arg "type" "${config}" \
                '.Tables[0].Rows[] | select(.type == $type) | .name') )
        IFS="${old_IFS}"
        for name in "${config_names[@]}"; do
            is_included=$(is_name_included "${name}")
            if [[ "${is_included}" == "true" ]]; then
                bosh config --type="${config}" --name="${name}"
            fi
        done
    fi \
        | sha1sum \
        | cut --delimiter=" " --field="1"
}

function is_name_included() {
    local name=$1

    local is_included  incl  excl
    if [[ ${#includes[@]} -eq 0 ]]; then
        is_included="true"
    else
        is_included="false"
        for incl in "${includes[@]}"; do
            if [[ "${name}" == ${incl} ]]; then
                is_included="true"
                break
            fi
        done
    fi
    for excl in "${excludes[@]}"; do
        if [[ "${name}" == ${excl} ]]; then
            is_included="false"
            break
        fi
    done
    echo "${is_included}"
}

function setup_bosh_access() {
    munge_with_source_file
    set_and_validate_vars
    export_bosh_vars
}

payload=$(mktemp $TMPDIR/script-request.XXXXXX)
cat > "${payload}" <&0
