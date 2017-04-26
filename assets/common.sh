payload=$(mktemp $TMPDIR/script-request.XXXXXX)

cat > $payload <&0

uri=$(jq -r '.source.uri // ""' < $payload)
username="$(jq -r '.source.username // ""' < $payload)"
password=$(jq -r '.source.password // ""' < $payload)
ca_cert=$(jq -r '.source.ca_cert // ""' < $payload)
config=$(jq -r '.source.config // ""' < $payload)

if [ -z "$uri" ]
then
  echo >&2 "invalid payload (missing uri):"
  cat $payload >&2
  exit 1
fi

if [ -z "$username" ]
then
  echo >&2 "invalid payload (missing username):"
  cat $payload >&2
  exit 1
fi

if [ -z "$password" ]
then
  echo >&2 "invalid payload (missing password):"
  cat $payload >&2
  exit 1
fi

if [ -z "$ca_cert" ]
then
  echo >&2 "invalid payload (missing ca_cert):"
  cat $payload >&2
  exit 1
fi

if [[ "$config" != "cloud" && "$config" != "runtime" ]]
then
  echo >&2 "invalid payload (config should be 'cloud' or 'runtime'):"
  cat $payload >&2
  exit 1
fi

calc_reference() {
  bosh -e $uri --client $username --client-secret $password --ca-cert $ca_cert ${config}-config | shasum | cut -f1 -d' '
}
