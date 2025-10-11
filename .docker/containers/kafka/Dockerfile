FROM quay.io/debezium/kafka:3.3.0.Final

COPY --from=mysql /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql /usr/lib64/mysql/plugin /usr/lib64/mysql/plugin
