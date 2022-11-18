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
* `name`: *Optional.* Property for named-configs. If omitted, will default to
  `default`.


### Example

``` yaml
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

### `in`: Download most recent config from BOSH director

This will download the config manifest. It will place two files in the target directory:

- `{cloud,runtime}-config.yml`: The config manifest
- `version`: The sha1 of the config manifest

_Note_: Only the most recent version is fetchable

### `out`: Update config on BOSH director

This will upload any given releases, and update the config with the specified
manifest.

#### Parameters

* `manifest`: *Required.* Path to a BOSH config manifest file.
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
