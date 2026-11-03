# audio-bridge · CachyOS (receptor)

```bash
./install.sh                 # deps, pipewire-roc opcional, config, comando en ~/.local/bin
audio-bridge on tcp          # o: roc
audio-bridge status
audio-bridge off
audio-bridge persist tcp     # fijo al iniciar sesión
audio-bridge unpersist
```

`install.sh` detecta tu subred y te imprime la IP que va en `PC_IP` de la Switch.

## Config (`config.local.env`)

| Variable | Default | Para qué |
|---|---|---|
| `LAN_SUBNET` | autodetectada | quién puede conectarse en modo tcp |
| `TCP_PORT` | 4713 | puerto del túnel |
| `ROC_SOURCE_PORT` / `ROC_REPAIR_PORT` | 10001 / 10002 | UDP de ROC |
| `ROC_LATENCY_MSEC` | 60 | buffer del receptor: menos = menos delay, más cortes |
| `ROC_FEC` | rs8m | `disable` / `rs8m` / `ldpc` (igual que en la Switch) |

## Firewall

```bash
sudo ufw allow from 192.168.1.0/24 to any port 4713 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 10001:10002 proto udp
```

Estado y logs: `~/.local/state/audio-bridge/`.
