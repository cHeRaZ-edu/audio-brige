# audio-bridge · Switch L4T (emisor)

```bash
./install.sh                       # deps, busca ROC en apt, te pide la IP de la PC
audio-bridge on tcp                # o: roc. Cambia la salida y mueve lo que esté sonando
audio-bridge on tcp --keep-default # crea el sink pero tú eliges qué apps mandar (applet KDE)
audio-bridge status
audio-bridge click both            # test de latencia a oído
audio-bridge off                   # regresa a la salida anterior
audio-bridge persist tcp           # sink fijo; luego elígelo en KDE
audio-bridge unpersist
```

## Test de latencia

`audio-bridge click both` suena un click en la bocina de la Switch **y** por el bridge al mismo tiempo.
Lo que tarda en llegar a los audífonos = latencia. Para un número: graba con el cel cerca de
la bocina y del audífono y mide en Audacity la distancia entre los dos picos.

## Config (`config.local.env`)

| Variable | Default | Para qué |
|---|---|---|
| `PC_IP` | (te la pide install.sh) | IP de CachyOS |
| `TCP_PORT` | 4713 | puerto del túnel |
| `TUNNEL_LATENCY_MSEC` | vacío | latencia pedida al túnel; prueba 20/40/80 |
| `ROC_SOURCE_PORT` / `ROC_REPAIR_PORT` | 10001 / 10002 | UDP de ROC |
| `ROC_FEC` | rs8m | igual que en CachyOS |

Estado y logs: `~/.local/state/audio-bridge/`.
