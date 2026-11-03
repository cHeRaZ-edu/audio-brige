#!/usr/bin/env bash
# Funciones compartidas (copia idéntica en cachyos/ y l4t/ para que cada carpeta sea autocontenida).
set -euo pipefail

AB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.env
source "$AB_DIR/config.env"
if [[ -f "$AB_DIR/config.local.env" ]]; then
  # shellcheck disable=SC1091
  source "$AB_DIR/config.local.env"
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/audio-bridge"
PW_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pipewire"
PERSIST_PULSE="$PW_CONF_DIR/pipewire-pulse.conf.d/audio-bridge.conf"
PERSIST_PW="$PW_CONF_DIR/pipewire.conf.d/audio-bridge.conf"
mkdir -p "$STATE_DIR"

log() { printf '\e[36m[audio-bridge]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[audio-bridge]\e[0m %s\n' "$*" >&2; }
die() { printf '\e[31m[audio-bridge] ERROR:\e[0m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "falta el comando '$1'"; }
hr() { printf '\n\e[1m== %s ==\e[0m\n' "$*"; }

check_pipewire() {
  need pactl
  [[ $EUID -ne 0 || -n ${AB_ALLOW_ROOT:-} ]] || die "córrelo como tu usuario, no con sudo (PipeWire es por sesión)"
  local server
  server=$(pactl info 2>/dev/null | grep '^Server Name' || true)
  [[ -n $server ]] || die "pactl no conecta al servidor de audio"
  [[ $server == *PipeWire* ]] || warn "el server no es PipeWire: $server"
}

is_active() { [[ -f "$STATE_DIR/bridge.ids" || -f "$STATE_DIR/bridge.pid" ]]; }
is_persisted() { [[ -f $PERSIST_PULSE || -f $PERSIST_PW ]]; }
active_mode() { cat "$STATE_DIR/bridge.mode" 2>/dev/null || echo "?"; }

guard_on() {
  is_active && die "ya está prendido ($(active_mode)). Corre: audio-bridge off"
  if is_persisted; then die "hay config persistente activa. Quítala con: audio-bridge unpersist"; fi
  return 0
}

# load_mod <modulo> [args...]
load_mod() {
  local mod=$1 id
  shift
  id=$(pactl load-module "$mod" "$@") || die "no cargó: $mod $*"
  echo "$id $mod" >>"$STATE_DIR/bridge.ids"
  log "cargado $mod (id $id)"
}

# spawn_pw <conf> -> instancia pipewire aparte que solo carga módulos nativos (ROC)
spawn_pw() {
  local conf=$1 pid
  need pipewire
  nohup pipewire -c "$conf" >"$STATE_DIR/bridge.log" 2>&1 &
  pid=$!
  disown
  echo "$pid" >"$STATE_DIR/bridge.pid"
  sleep 1
  kill -0 "$pid" 2>/dev/null || { rm -f "$STATE_DIR/bridge.pid"; die "pipewire -c murió, revisa $STATE_DIR/bridge.log"; }
  log "pipewire aparte corriendo (pid $pid), log: $STATE_DIR/bridge.log"
}

stop_bridge() {
  local f="$STATE_DIR/bridge.ids" p="$STATE_DIR/bridge.pid"
  if [[ -f $f ]]; then
    tac "$f" | while read -r id mod; do
      if pactl unload-module "$id" 2>/dev/null; then log "descargado $mod ($id)"; else warn "ya no existía $mod ($id)"; fi
    done
    rm -f "$f"
  fi
  if [[ -f $p ]]; then
    local pid
    pid=$(<"$p")
    if kill "$pid" 2>/dev/null; then log "detenido pipewire aparte ($pid)"; else warn "pid $pid ya no corría"; fi
    rm -f "$p"
  fi
  rm -f "$STATE_DIR/bridge.mode"
}

list_sinks() { pactl list short sinks 2>/dev/null | awk '{print $2}' || true; }
sink_exists() { local s; s=$(list_sinks); grep -qx -- "$1" <<<"$s"; }

# wait_sink <nombre> [segundos]
wait_sink() {
  local name=$1 secs=${2:-8} i
  for ((i = 0; i < secs * 2; i++)); do
    sink_exists "$name" && return 0
    sleep 0.5
  done
  return 1
}

roc_available() {
  compgen -G "/usr/lib/pipewire-0.3/libpipewire-module-roc-*.so" >/dev/null ||
    compgen -G "/usr/lib/*/pipewire-0.3/libpipewire-module-roc-*.so" >/dev/null
}

require_roc() {
  roc_available && return 0
  die "no encuentro libpipewire-module-roc-*.so. Corre ./install.sh para ver cómo instalarlo"
}

# Config para una instancia pipewire aparte. $1 = bloque del módulo.
pw_standalone_conf() {
  cat <<EOF
context.properties = { log.level = 2 }
context.spa-libs = {
  audio.convert.* = audioconvert/libspa-audioconvert
  support.*       = support/libspa-support
}
context.modules = [
  { name = libpipewire-module-rt flags = [ ifexists nofail ] }
  { name = libpipewire-module-protocol-native }
  { name = libpipewire-module-client-node }
  { name = libpipewire-module-adapter }
$1
]
EOF
}

restart_pipewire() {
  log "reiniciando PipeWire..."
  systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null ||
    systemctl --user restart pipewire pipewire-pulse
  sleep 2
}

unpersist() {
  local any=0
  for f in "$PERSIST_PULSE" "$PERSIST_PW"; do
    if [[ -f $f ]]; then rm -f "$f"; log "borrado $f"; any=1; fi
  done
  if ((any)); then restart_pipewire; else log "no había nada persistido"; fi
}

show_persisted() {
  local any=0
  for f in "$PERSIST_PULSE" "$PERSIST_PW"; do
    [[ -f $f ]] && { echo "persistido: $f"; any=1; }
  done
  ((any)) || echo "persistido: no"
}
