#!/usr/bin/env bash
# Instalador CachyOS (receptor). Córrelo como tu usuario: ./install.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
say() { printf '\e[36m[install]\e[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || { echo "No uses sudo, córrelo como tu usuario"; exit 1; }
chmod +x "$DIR/audio-bridge"

# 1. Dependencias base
for c in pactl pipewire ss ip; do
  command -v "$c" >/dev/null || { echo "falta $c (sudo pacman -S pipewire pipewire-pulse iproute2)"; exit 1; }
done
info=$(pactl info 2>/dev/null || true)
if [[ $info == *"on PipeWire"* ]]; then say "PipeWire OK"; else say "OJO: pactl no reporta PipeWire"; fi

# 2. ROC (opcional)
if compgen -G "/usr/lib/pipewire-0.3/libpipewire-module-roc-*.so" >/dev/null; then
  say "módulos ROC: ya instalados"
else
  read -rp "¿Instalar pipewire-roc para el modo roc? [s/N] " r
  if [[ ${r,,} == s* ]]; then sudo pacman -S --needed pipewire-roc; else say "sin ROC (solo modo tcp por ahora)"; fi
fi

# 3. Config local
if [[ ! -f $DIR/config.local.env ]]; then
  cp "$DIR/config.env" "$DIR/config.local.env"
  subnet=$(ip -o -4 route show scope link proto kernel 2>/dev/null | awk '!/docker|br-|virbr|veth/ {print $1; exit}')
  if [[ -n ${subnet:-} ]]; then
    sed -i "s#^LAN_SUBNET=.*#LAN_SUBNET=$subnet#" "$DIR/config.local.env"
    say "LAN_SUBNET detectada: $subnet"
  fi
  say "config creada: $DIR/config.local.env"
else
  say "config.local.env ya existe, no la toco"
fi

# 4. Comando en el PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/audio-bridge" "$HOME/.local/bin/audio-bridge"
say "comando: ~/.local/bin/audio-bridge"
[[ :$PATH: == *":$HOME/.local/bin:"* ]] || say "agrega ~/.local/bin a tu PATH"

# 5. Firewall
if command -v ufw >/dev/null && sudo -n true 2>/dev/null && sudo ufw status | grep -q active; then
  say "ufw activo, recuerda abrir 4713/tcp y 10001:10002/udp para tu LAN"
fi

echo
say "IP de esta PC (ponla como PC_IP en la Switch):"
ip -o -4 addr show scope global | awk '{print "   "$2": "$4}'
echo
say "Prueba: audio-bridge on tcp"
