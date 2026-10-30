#!/usr/bin/env bash
# Aplica a configuração InfraDev Remote no código antes do build.
# Roda no CI logo depois do checkout (Windows, macOS, Linux, Android e iOS).
# Usa "sed -i.bak" porque funciona igual no sed do GNU e do macOS.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/infradev/branding.env"

CONFIG="$ROOT/libs/hbb_common/src/config.rs"

sed -i.bak \
  -e "s|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"${INFRADEV_HOST}\"];|" \
  -e "s|^pub const RS_PUB_KEY: &str = \".*\";|pub const RS_PUB_KEY: \&str = \"${INFRADEV_KEY}\";|" \
  "$CONFIG"
rm -f "$CONFIG.bak"

# Falha o build se a troca não aconteceu (por exemplo, se o código do RustDesk mudar).
grep -q "RENDEZVOUS_SERVERS: &\[&str\] = &\[\"${INFRADEV_HOST}\"\];" "$CONFIG" \
  || { echo "InfraDev: não consegui embutir o servidor em $CONFIG" >&2; exit 1; }
grep -qF "RS_PUB_KEY: &str = \"${INFRADEV_KEY}\";" "$CONFIG" \
  || { echo "InfraDev: não consegui embutir a chave em $CONFIG" >&2; exit 1; }

# Servidor de API (login e catálogo de endereços): sem isso o app usaria o admin.rustdesk.com.
COMMON="$ROOT/src/common.rs"
sed -i.bak \
  -e "s|^    \"https://admin.rustdesk.com\".to_owned()$|    \"http://${INFRADEV_HOST}:21114\".to_owned()|" \
  "$COMMON"
rm -f "$COMMON.bak"
grep -qF "\"http://${INFRADEV_HOST}:21114\".to_owned()" "$COMMON" \
  || { echo "InfraDev: não consegui embutir o servidor de API em $COMMON" >&2; exit 1; }

echo "InfraDev: servidor ${INFRADEV_HOST} e chave embutidos."
