#!/usr/bin/env bash
set -euo pipefail

# Backup diário de gravações para OneDrive usando rclone.
# - Executar via cron às 00:10.
# - Faz backup da pasta do dia anterior.
# - Envia para o remote baseado no dia do mês:
#   * dia par   -> diasPares
#   * dia ímpar -> diaImpar

SOURCE_BASE="/home/usua1/frigate/storage/recordings"
REMOTE_EVEN="diasPares"
REMOTE_ODD="diaImpar"
REMOTE_BASE_DIR="frigate/recordings"
RCLONE_BIN="rclone"
LOG_FILE="/var/log/backup_onedrive.log"

YESTERDAY="$(date -d 'yesterday' +%F)"
DAY_OF_MONTH="$(date -d "$YESTERDAY" +%d)"
SOURCE_DIR="${SOURCE_BASE}/${YESTERDAY}"

if (( 10#$DAY_OF_MONTH % 2 == 0 )); then
  REMOTE_NAME="$REMOTE_EVEN"
else
  REMOTE_NAME="$REMOTE_ODD"
fi

REMOTE_PATH="${REMOTE_NAME}:${REMOTE_BASE_DIR}/${YESTERDAY}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[$(date '+%F %T')] ERRO: diretório não encontrado: $SOURCE_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$(date '+%F %T')] Iniciando backup de $SOURCE_DIR para $REMOTE_PATH" | tee -a "$LOG_FILE"

"$RCLONE_BIN" copy "$SOURCE_DIR" "$REMOTE_PATH" \
  --create-empty-src-dirs \
  --transfers 8 \
  --checkers 16 \
  --log-file "$LOG_FILE" \
  --log-level INFO

echo "[$(date '+%F %T')] Backup concluído com sucesso: $SOURCE_DIR -> $REMOTE_PATH" | tee -a "$LOG_FILE"
