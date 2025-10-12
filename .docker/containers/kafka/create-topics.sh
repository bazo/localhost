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

cmd="mysql --protocol=tcp --ssl-mode=DISABLED -h \"$MYSQL_HOST\" -P \"$MYSQL_PORT\" -u \"$MYSQL_USER\" -p\"$MYSQL_PASS\" -N -e \"SHOW TABLES IN $MYSQL_DB;\""
tables=$(eval "$cmd")

if [ -z "${tables:-}" ]; then
  echo "❌ Žiadne tabuľky sa nenašli v databáze '$MYSQL_DB'"
  exit 1
fi

count=$(echo "$tables" | wc -w)
echo "📋 Počet tabuliek: $count"

# --- Progress funkcie ---
start_time=$(date +%s)
current=0

progress() {
  current=$((current + 1))
  elapsed=$(( $(date +%s) - start_time ))
  percent=$(( current * 100 / count ))
  avg_time=$(awk "BEGIN { print $elapsed / $current }")
  remaining=$(awk "BEGIN { print int(($count - $current) * $avg_time) }")

  printf "\r[%3d%%] ⏳ %d/%d (ETA: %ds)" "$percent" "$current" "$count" "$remaining"
}

# --- Vytváranie topicov ---
echo "🪣 Vytváram Kafka topicy..."
for tbl in $tables; do
  topic="${TOPIC_PREFIX}.${MYSQL_DB}.${tbl}"
  /kafka/bin/kafka-topics.sh --create --if-not-exists \
    --topic "$topic" \
    --bootstrap-server "$KAFKA_BROKER" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION" \
    >/dev/null 2>&1 || { echo; echo "❌ Chyba pri vytváraní topicu $topic"; exit 1; }

  progress
done

echo -e "\n✅ Hotovo."
/kafka/bin/kafka-topics.sh --list --bootstrap-server "$KAFKA_BROKER" | grep "^$TOPIC_PREFIX" || true
