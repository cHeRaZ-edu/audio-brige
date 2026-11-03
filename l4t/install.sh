#!/usr/bin/env bash
# Instalador Switch L4T Ubuntu (emisor). Córrelo como tu usuario: ./install.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
say() { printf '\e[36m[install]\e[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || { echo "No uses sudo, córrelo como tu usuario"; exit 1; }
chmod +x "$DIR/audio-bridge"

# 1. Dependencias base
missing=()
command -v pactl >/dev/null || missing+=(pulseaudio-utils)
command -v pw-play >/dev/null || missing+=(pipewire-bin)
command -v python3 >/dev/null || missing+=(python3)
command -v iw >/dev/null || missing+=(iw)
if ((${#missing[@]})); then
  say "faltan: ${missing[*]}"
  read -rp "¿Instalar con apt? [S/n] " r
  [[ ${r,,} == n* ]] || sudo apt install -y "${missing[@]}"
fi
info=$(pactl info 2>/dev/null || true)
if [[ $info == *"on PipeWire"* ]]; then say "PipeWire OK"; else say "OJO: pactl no reporta PipeWire"; fi

# 2. ROC (opcional). En Noble ARM64 el nombre del paquete está por confirmar.
if compgen -G "/usr/lib/*/pipewire-0.3/libpipewire-module-roc-*.so" >/dev/null ||
  compgen -G "/usr/lib/pipewire-0.3/libpipewire-module-roc-*.so" >/dev/null; then
  say "módulos ROC: ya instalados"
else
  say "módulos ROC: no encontrados. Candidatos en apt:"
  apt-cache search --names-only 'roc' 2>/dev/null | grep -iE 'pipewire|libroc|roc-toolkit' || echo "   (ninguno)"
  say "si ves uno tipo pipewire-module-roc / pipewire-roc: sudo apt install <paquete>"
  say "si no hay, usa modo tcp (no necesita nada extra)"
fi

# 3. Config local
if [[ ! -f $DIR/config.local.env ]]; then
  cp "$DIR/config.env" "$DIR/config.local.env"
  say "config creada: $DIR/config.local.env"
fi
# shellcheck disable=SC1091
source "$DIR/config.local.env"
if [[ -z ${PC_IP:-} ]]; then
  read -rp "IP de tu CachyOS (sale en su ./install.sh): " ip
  if [[ -n $ip ]]; then
    sed -i "s#^PC_IP=.*#PC_IP=$ip#" "$DIR/config.local.env"
    say "PC_IP=$ip"
  fi
else
  say "PC_IP=$PC_IP (ya configurada)"
fi

# 4. Comando en el PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/audio-bridge" "$HOME/.local/bin/audio-bridge"
say "comando: ~/.local/bin/audio-bridge"
[[ :$PATH: == *":$HOME/.local/bin:"* ]] || say "agrega ~/.local/bin a tu PATH (o abre otra terminal)"

echo
say "Prueba (con la PC en 'audio-bridge on tcp'): audio-bridge on tcp"
