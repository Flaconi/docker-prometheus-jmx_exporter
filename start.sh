#!/bin/sh
set -e

gomplate --input-dir=/opt/jmx_exporter/config \
  --output-dir=/opt/jmx_exporter/config \
  --datasource config=/opt/jmx_exporter/config/config.yml

exec gosu nobody java -jar /opt/jmx_exporter/"${JMX_EXPORTER_JAR}" "${EXPORTER_PORT}" /opt/jmx_exporter/config/config.yml
