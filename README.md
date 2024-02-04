# BOSH Config Resource

A resource that will allow updating cloud and runtime configs using the
[BOSH CLI v2][cli_v2].

[cli_v2]: https://bosh.io/docs/cli-v2/

## Adding to your pipeline

To use the BOSH Config Resource, you must declare it in your pipeline as a
resource type:

```yaml
resource_types:
- name: bosh-config
  type: registry-image
  source:
    repository: cfcommunity/bosh-config-resource
```

## Source Configuration

* `target`: *Optional.* The address of the BOSH director which will be used for
  the config. If omitted, `source_file` must be specified via out parameters, as
  documented below.
* `client`: *Required.* The username or UAA client ID for the BOSH director.
* `client_secret`: *Required.* The password or UAA client secret for the BOSH
  director.
* `ca_cert`: *Optional.* CA certificate used to validate SSL connections to
  Director and UAA. If omitted, the director's certificate must be already
  trusted.
* `config`: *Required.* Type of config to update.
* `name`: *Optional.* Property for named-configs. Illegal when `all` is `true`.
  If omitted when `all` is `false`, it will default to `default`, which is the
  usual name of default BOSH configs.
* `all`: *Optional.* Set to `true` when in need for `check` to watch at changes
  on _all_ configs of the type spcified with `config`. Defaults to `false`.
* `includes`: *Optional.* An allow-list of config names. When `all` is set to
  `true`, an array of config names to include. If not empty, any config name
  that is not in this array is not considered. Globbing _à la Bash_ is supported.
* `excludes`: *Optional.* A deny-list list of config names. When `all` is set to
  `true`, an array of config names to exclude. Any config name that is in this
  array is not considered. This takes precedence over anything listed in the
  `includes` array. Globbing _à la Bash_ is supported.

### Example

In this first example, the cloud config named `my-named-config` is watched at
(by `check` steps), fetched (by `get` steps) or updated (by `put` steps).

```yaml
- name: staging
  type: bosh-config
  source:
    target: https://bosh.example.com:25555
    client: admin
    client_secret: admin
    ca_cert: "-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----"
    config: cloud
    name: my-named-config
```

In the second example below, all could configs which name matches the
`*-network` Bash-globbing pattern will be watched at (by `check` steps),
fetched (by `get` steps) or updated (by `put` steps).

```yaml
- name: network-configs
  type: bosh-config
  source:
    target: https://bosh.example.com:25555
    client: admin
    client_secret: admin
    ca_cert: "-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----"
    config: cloud
    all: true
    includes:
      - "*-network"
```

### Dynamic Source Configuration

Sometimes source configuration cannot be known ahead of time, such as when a BOSH director is created as part of your
pipeline. In these scenarios, it is helpful to be able to have a dynamic source configuration. In addition to the
normal parameters for `put`, the following parameters can be provided to redefine the source:

* `source_file`: *Optional.* Path to a file containing a YAML or JSON source
  config. This allows the target to be determined at runtime, e.g. by acquiring
  a BOSH lite instance using the
  [Pool resource](https://github.com/concourse/pool-resource). The content of
  the `source_file` should have the same structure as the source configuration
  for the resource itself. The `source_file` will be merged into the exist
  source configuration.

_Notes_:
 - `target` must **ONLY** be configured via the `source_file` otherwise the implicit `get` will fail after the `put`.
 - This is only supported for a `put`.

## Behaviour

### `get` Step (`in` script): Download most recent config from BOSH director

This will download the config manifest. It will place two files in the target directory:

- When `source.all` is `false`
  - `{cloud,runtime}-config.yml`: The config manifest
  - `version`: The sha1 of the config manifest
- When `source.all` is `true`
  - `<name>-{cloud,runtime}-config.yml`: The config manifest named `<name>`
  - `version`: The sha1 of the concatenated config manifests

_Note_: Only the most recent version of configs is fetchable

### `put` Step (`out` script): Update config on BOSH director

This will upload any given releases, and update the config(s) with the specified
manifest(s).

When `source.all` is `false` the config with the type defined in `source.config`
and name defined by `source.name` is updated. Any `params.ops_files` are
applied, and any `params.vars` are interpolated.

When `source.all` is `true`, then the configs defined in `params.manifests`,
with given name (key) and manifest file (value), are updated. Theses must all be
of the type defined in `source.config`. The `params.ops_files` and `params.vars`
do apply to _all_ of them. `source.includes` and `source.excludes` apply to the
names defined in the keys of the `params.manifests` dictionary.

#### Parameters

* `manifest`: *Required when `all` is `false`.* Path to a BOSH config manifest
  file.
* `manifests`: *Required when `all` is `true`.* Dictionary of config names
  (keys) and paths to their respective manifest files (values).
* `ops_files`: *Optional.* Array of paths to ops files to apply.
* `vars`: *Optional.* Dictionary of variables to apply.
* `releases`: *Optional.* Array of paths to bosh releases to upload.
* `source_file`: *Optional.* Path to a file containing a BOSH director address.
  This allows the target to be determined at runtime, e.g. by acquiring a BOSH
  lite instance using the
  [Pool resource](https://github.com/concourse/pool-resource).
  If both `source_file` and `target` are specified, `source_file` takes
  precedence.


``` yaml
# Update config
- put: staging
  params:
    manifest: path/to/config-manifest.yml
    ops_files:
      - path/to/ops-file.yml
      - path/to/another-ops-file.yml
    releases:
      - path/to/first/release
      - path/to/second/release
    vars:
      key: value
      foo: bar
```



## Authors and License

Copyright © 2017-2020, Gwen Ivett, Geoff Franks, Ruben Koster, Konstantin
Troshin, Konstantin Kiess, Andrei Krasnitski, Daniel Jones

Copyright © 2022-present, Benjamin Gandon, Gstack

Like Concourse, the BOSH config resource is released under the terms of the
[Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0).

<!--
# Local Variables:
# indent-tabs-mode: nil
# End:
-->
