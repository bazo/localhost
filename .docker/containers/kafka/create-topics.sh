#!/usr/bin/env bash
set -euo pipefail

# --- Konfigurácia ---
MYSQL_HOST="${MYSQL_HOST:-host.docker.internal}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-root}"
MYSQL_DB="${MYSQL_DB:-forclimb_presta}"

KAFKA_BROKER="${KAFKA_BROKER:-kafka:9092}"
TOPIC_PREFIX="${TOPIC_PREFIX:-forclimb}"
PARTITIONS="${PARTITIONS:-1}"
REPLICATION="${REPLICATION:-1}"

echo "🔍 Načítavam tabuľky z MySQL ($MYSQL_DB@$MYSQL_HOST:$MYSQL_PORT) ..."

# tables=$(mysql \
#   --protocol=tcp \
#   -h "$MYSQL_HOST" \
#   -P "$MYSQL_PORT" \
#   -u"$MYSQL_USER" \
#   -p"$MYSQL_PASS" \
#   -N -e "SHOW FULL TABLES IN \`$MYSQL_DB\` WHERE Table_type='BASE TABLE';" \
#   2>/dev/null | awk '{print $1}')


cmd="mysql --protocol=tcp --ssl-mode=DISABLED -h \"$MYSQL_HOST\" -P \"$MYSQL_PORT\" -u \"$MYSQL_USER\" -p\"$MYSQL_PASS\" -N -e \"SHOW TABLES IN $MYSQL_DB;\""

# Výpis príkazu na obrazovku
echo "Executing command: $cmd"

# Vykonanie príkazu a uloženie výstupu do premennej 'tables'
tables=$(eval "$cmd")

if [ -z "${tables:-}" ]; then
  echo "❌ Žiadne tabuľky sa nenašli v databáze '$MYSQL_DB'"
  exit 1
fi

echo "🪣 Vytváram Kafka topicy..."
for tbl in $tables; do
  topic="${TOPIC_PREFIX}.${tbl}"
  echo "→ $topic"
  /kafka/bin/kafka-topics.sh --create --if-not-exists \
    --topic "$topic" \
    --bootstrap-server "$KAFKA_BROKER" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION" \
  || { echo "❌ Chyba pri vytváraní topicu $topic"; exit 1; }
done

echo "✅ Hotovo."
/kafka/bin/kafka-topics.sh --list --bootstrap-server "$KAFKA_BROKER" | grep "^$TOPIC_PREFIX" || true
