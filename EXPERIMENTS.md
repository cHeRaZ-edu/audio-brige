# Bitácora de pruebas

Una fila por prueba. **Desfase** = qué tanto notas el audio atrasado vs el video de la Switch
(o lo que mida `audio-bridge click both`). **Cortes** = chasquidos / huecos en 5 min.

| # | Fecha | Modo | Latencia cfg | Wi-Fi Switch (banda/canal) | Ping prom | Desfase | Cortes | CPU Switch (`pw-top`) | Notas |
|---|-------|------|--------------|----------------------------|-----------|---------|--------|-----------------------|-------|
| 1 |       | tcp  | default      |                            |           |         |        |                       |       |
| 2 |       | tcp  | 40           |                            |           |         |        |                       |       |
| 3 |       | roc  | 60 / rs8m    |                            |           |         |        |                       |       |
| 4 |       | roc  | 30 / rs8m    |                            |           |         |        |                       |       |

## Hipótesis a verificar

- [ ] `module-tunnel-sink` de pipewire-pulse acepta `latency_msec` (si truena al cargar, déjalo vacío)
- [ ] Hay paquete de módulos ROC para Ubuntu Noble ARM64 (`./install.sh` en la Switch lista candidatos)
- [ ] ROC aguanta mejor que TCP con la Switch en 2.4 GHz
- [ ] Desfase con video tolerable (< ~80 ms); si no: `--audio-delay` en mpv / delay en el reproductor
- [ ] Con `persist tcp`, si la PC está apagada al iniciar la Switch, el túnel se reconecta solo al prender la PC
- [ ] Consumo de CPU del emisor en el Tegra X1 es despreciable

## Hallazgos

-
