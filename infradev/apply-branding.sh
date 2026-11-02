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

# ---------------------------------------------------------------------------
# Marca visual: ícones, logos e nome mostrado ao usuário.
# ---------------------------------------------------------------------------

# Troca a primeira ocorrência de um texto exato; falha se o texto não existir.
replace_once() {
  local file="$ROOT/$1"
  grep -qF -- "$2" "$file" || { echo "InfraDev: texto não encontrado em $1: $2" >&2; exit 1; }
  OLD="$2" NEW="$3" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$file"
}

# Ícones e logos gerados por infradev/gerar-icones.py
cp -R "$ROOT/infradev/assets/." "$ROOT/"

# Textos traduzidos que citam "RustDesk" passam a mostrar o nome da InfraDev.
replace_once src/lang.rs 'if !crate::is_rustdesk() {' 'if true {'
replace_once src/lang.rs 'let app_name = crate::get_app_name();' "let app_name = \"${INFRADEV_APP_NAME}\".to_owned();"

# Android: nome do app, nome do serviço de acessibilidade e fundo do ícone
replace_once flutter/android/app/src/main/AndroidManifest.xml 'android:label="RustDesk"' "android:label=\"${INFRADEV_APP_NAME}\""
replace_once flutter/android/app/src/main/AndroidManifest.xml 'android:label="RustDesk Input"' "android:label=\"${INFRADEV_APP_NAME} Input\""
replace_once flutter/android/app/src/main/res/values/ic_launcher_background.xml '#ffffff' "${INFRADEV_ICON_BG}"
replace_once flutter/lib/mobile/pages/home_page.dart 'Text(bind.mainGetAppNameSync())' "Text('${INFRADEV_APP_NAME}')"
replace_once flutter/lib/main.dart ': bind.mainGetAppNameSync(),' ": '${INFRADEV_APP_NAME}',"

# Windows: descrição e nome do produto nas propriedades do .exe
replace_once flutter/windows/runner/Runner.rc '"FileDescription", "RustDesk Remote Desktop"' "\"FileDescription\", \"${INFRADEV_APP_NAME}\""
replace_once flutter/windows/runner/Runner.rc '"ProductName", "RustDesk"' "\"ProductName\", \"${INFRADEV_APP_NAME}\""

# Linux: nome no menu de aplicativos
replace_once res/rustdesk.desktop 'Name=RustDesk' "Name=${INFRADEV_APP_NAME}"

# Troca todas as ocorrências de um texto exato nos arquivos Dart; falha se não achar nenhuma.
replace_all_dart() {
  local files
  files=$(grep -rlF --include='*.dart' -- "$1" "$ROOT/flutter/lib" | grep -v '/web/' || true)
  [ -n "$files" ] || { echo "InfraDev: texto não encontrado no Flutter: $1" >&2; exit 1; }
  for f in $files; do
    OLD="$1" NEW="$2" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$f"
  done
}

# Links do site e de download apontam para a InfraDev.
# O aviso de privacidade e a documentação técnica continuam apontando para o RustDesk.
replace_all_dart "https://rustdesk.com/download" "${INFRADEV_DOWNLOAD}"
replace_all_dart "'https://rustdesk.com'" "'${INFRADEV_SITE}'"
replace_all_dart "'https://rustdesk.com/'" "'${INFRADEV_SITE}'"
replace_all_dart "Text('rustdesk.com'" "Text('${INFRADEV_SITE_LABEL}'"

# Não procurar atualização do RustDesk oficial: ela trocaria o app por uma versão
# sem a marca e sem o servidor da InfraDev. Atualizações vêm deste fork.
replace_once src/common.rs 'pub fn check_software_update() {' 'pub fn check_software_update() {
    if true {
        return;
    }'

echo "InfraDev: marca visual aplicada (${INFRADEV_APP_NAME})."

echo "InfraDev: servidor ${INFRADEV_HOST} e chave embutidos."
