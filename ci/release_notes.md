### Improvements

- Updated pipeline including basic unit tests, now able to test GitHub Pull Requests
- Have `source.ca_cert` be optional in case the CA certificate is already trusted (credit: @Infra-Red, see #6)
- Support for `params.ops_files` and `params.vars` in `put` steps (credit: $DanielJonesEB, see #9)
