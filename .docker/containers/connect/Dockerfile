FROM quay.io/debezium/connect:3.3.0.Final

USER root

ARG KAFKA_VERSION=4.1.0

COPY ./plugins /kafka/connect/my-plugins

# Pridaj Apache FileStream konektory (z Kafka 4.1.0)
# RUN mkdir -p /usr/share/filestream-connectors && \
#     curl -sSL https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_2.13-4.1.0.tgz \
#       | tar -xz --strip-components=1 -C /tmp && \
#     cp /tmp/libs/connect-file-*.jar /usr/share/filestream-connectors/ && \
#     rm -rf /tmp/*

RUN rm /kafka/config/log4j.properties

ARG UID=1000

RUN usermod -u ${UID} kafka

USER kafka

# Nastav plugin path – Debezium + FileStream
ENV PLUGIN_PATH=/kafka/connect,/debezium/connect,/usr/share/filestream-connectors
