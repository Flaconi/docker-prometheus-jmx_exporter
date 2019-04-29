# Docker image for JMX Prometheus exporter

       +---------+
       |   JVM 1 |           +------------+
       |---------|+--------> |JMX exporter|-------------+
       |         |           +------------+             |
       |   JMX 1 |                                      |
       +---------+                                      v
                                                     +-------------+
       +---------+                                   |             |
       |   JVM 2 |           +------------+          |             |
       |---------|+--------> |JMX exporter|--------->|             |
       |         |           +------------+          | Prometheus  |
       |   JMX 2 |                                   |             |
       +---------+                                   |             |
                                                     +-------------+
       +---------+                                      ^
       |   JVM 3 |           +------------+             |
       |---------|+--------> |JMX exporter|-------------+
       |         |           +------------+
       |   JMX 3 |
       +---------+

## About

This is the [official JMX Prometheus exporter][1], running inside a Docker
container.

As one can read on the exporter documentation page, it can also run as a Java
agent. However, it is not always an option to do so and so, mainly for
convenience purposes, we run it as a container.

## Usage

Check out the [example](./example/README.md).

## Configuration

At the moment, this is done exclusively through _environment variables_ passed
to the container. We do want to add support for passing the rules definitions as
a `YAML` file that you will be able to mount in the container.

We are trying to differentiate between build & run time with Docker build args
and ENV vars.

### Build time

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| GOMPLATE\_VERSION | Gomplate version to use | string | `v3.3.1` | no |
| GOSU\_VERSION | gosu version to use | string | `1.11` | no |
| JMX\_EXPORTER\_VERSION | JMX exporter version to use | string | `0.11.0` | no |

### Run time

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| JMX\_HOST | The JMX host from where you want to collect metrics | string | `localhost` | yes |
| JMX\_PORT | The port of the JMX host from where you want to collect metrics. | integer | `1099` | yes |
| JMX\_USERNAME | If enabled, the user name required to connect to JMX | string | `` | no |
| JMX\_PASSWORD | If enabled, the password required to connect to JMX | string | `` | no |
| JMX\_RULES | Rules for exposing JMX metrics for Prometheus to scrape | list | `` | yes |
| EXPORTER\_PORT | TCP port behind which the exporter will listen. Endpoint is `<EXPORTER_PORT>/metrics` | integer | `10990` | no |

*Important*: Be advised of the escaping required, as mentioned in the
[example](./example/README.md##Standalone)

## FAQ

### Multiple JVMs

The exporter can only expose JMX metrics from one JVM. If you want to scrape
metrics from multiple JVMs, you'll need to run multiple exporters.

### Metrics of the exporter

The exporter itself can also expose JMX metrics of its own, but we chose not to
do so. If there will be a need for this, we will add it as a debug option.

### Logs

The `stdout` and `stderr` streams are available. Yes, for now the Java stack
traces are multi-line. The logs will be wrapped in a `JSON` object soon.

### Security

#### Authentication

If your JMX endpoint is configured to use authentication, the you can pass the
username and password to the exporter as shown in the parameters table.

#### Encryption

The exporter can utilise a TLS certificate for its endpoint, however, we chose
not to implement this in the first iteration.

The exporter should be able to connect to JMX endpoints that use TLS.

#### Docker container

There is only one process running inside the container and it runs as the
unprivileged `nobody` user.

[1]: https://github.com/prometheus/jmx_exporter

## License

[MIT](LICENSE)

Copyright (c) 2019 [Flaconi GmbH](https://github.com/Flaconi)
