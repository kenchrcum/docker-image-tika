#!/bin/sh
set -e

TIKA_JAR="/tika-server-standard-${TIKA_VERSION}.jar"
CLASSPATH="${TIKA_JAR}:/tika-extras/*"

# Support JAVA_OPTS env var for JVM tuning (e.g. tika.javaOpts in Helm chart)
# shellcheck disable=SC2086
exec java ${JAVA_OPTS:-} -cp "${CLASSPATH}" \
  org.apache.tika.server.core.TikaServerCli \
  -h 0.0.0.0 \
  "$@"
