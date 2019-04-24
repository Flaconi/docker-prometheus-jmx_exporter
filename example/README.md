# Kafka Broker & Zookeeper

This example aims to demonstrate how one could use the Prometheus JMX exporter
with the two mentioned JVMs.

## Docker Compose

Bring up the containers:

```shell
docker-compose build
docker-compose up -d
```

Query the metrics:

```shell
# Broker
curl localhost:91/metrics

# Zookeeper
curl localhost:92/metrics
```

The rules for the JMX exporters config were taken from the examples [here][1].

*Nota bene*: We need to use `$$` instead of `$` in the rules config.
See the [variable substitution][2] doc page to learn more.

## Standalone

Here's an example, if you want to run the JMX exporter container locally,
without Docker Compose:

```shell
export JMX_RULES=$(cat << EOF
- pattern : kafka.cluster<type=(.+), name=(.+), topic=(.+), partition=(.+)><>Value
  name: kafka_cluster_\$1_\$2
  labels:
    topic: "\$3"
    partition: "\$4"
EOF
)

docker run --rm --interactive --tty \
  --env JMX_HOST=somehost \
  --env JMX_PORT=10991 \
  --env JMX_RULES \
  --name jmx-exporter \
  -p 92:10990 \
  flaconi-prometheus-jmx-exporter

curl localhost:92/metrics
```

*Nota bene*: We need to escape the `$` using `\$` in the rules config.

[1]: https://github.com/prometheus/jmx_exporter/tree/master/example_configs
[2]: https://docs.docker.com/compose/compose-file/#variable-substitution
