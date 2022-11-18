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
  the config.
* `client`: *Required.* The username or UAA client ID for the BOSH director.
* `client_secret`: *Required.* The password or UAA client secret for the BOSH
  director.
* `ca_cert`: *Required.* CA certificate used to validate SSL connections to
  Director and UAA.
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
* `releases`: Array of paths to bosh releases to upload

``` yaml
# Update config
- put: staging
  params:
    manifest: path/to/config-manifest.yml
    releases:
      - path/to/first/release
      - path/to/second/release
```



## Authors and License

Copyright © 2017-2020, Gwen Ivett, Geoff Franks, Ruben Koster, Konstantin
Troshin, Konstantin Kiess

Copyright © 2022-present, Benjamin Gandon, Gstack

Like Concourse, the BOSH config resource is released under the terms of the
[Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0).

<!--
# Local Variables:
# indent-tabs-mode: nil
# End:
-->
