# audio-bridge

Manda el audio de la **Switch (Switchroot L4T Ubuntu)** a **CachyOS** por la red,
para oír Switch + PC en los mismos audífonos.

```
 Switch · l4t/  (emisor)                          CachyOS · cachyos/  (receptor)
 apps ─▶ sink "bridge_pc" / "bridge_roc" ──LAN──▶ PipeWire ─▶ audífonos
```

| Carpeta | Dispositivo | Qué hace |
|---|---|---|
| [`cachyos/`](cachyos/) | PC CachyOS | recibe y mezcla en tu salida |
| [`l4t/`](l4t/) | Switch L4T Ubuntu Noble | crea un sink de red y manda todo ahí |

## Instalar

**CachyOS**
```bash
git clone --filter=blob:none --sparse https://github.com/cHeRaZ-edu/audio-brige ~/audio-bridge
cd ~/audio-bridge && git sparse-checkout set cachyos
cd cachyos && ./install.sh
```

**Switch (L4T)**
```bash
git clone --filter=blob:none --sparse https://github.com/cHeRaZ-edu/audio-brige ~/audio-bridge
cd ~/audio-bridge && git sparse-checkout set l4t
cd l4t && ./install.sh
```

> Con sparse checkout cada equipo baja solo su carpeta. Si prefieres todo: `git clone` normal.
> Actualizar: `git pull` (tu `config.local.env` no se toca).

## Usar

```bash
# 1. PC
audio-bridge on tcp
# 2. Switch
audio-bridge on tcp
# apagar (en cualquier orden)
audio-bridge off
```

Los dos lados tienen que estar en el **mismo modo**:

| Modo | Cómo | Pros | Contras |
|---|---|---|---|
| `tcp` | túnel pulse (`module-tunnel-sink`) | viene con PipeWire, nada extra | si se pierde un paquete en Wi-Fi, espera → picos de delay |
| `roc` | ROC sobre UDP con FEC | hecho para audio en tiempo real, latencia ajustable | requiere módulos ROC en los dos |

`audio-bridge status` en cualquiera de los dos te da el diagnóstico.
Cuando encuentres tu setup: `audio-bridge persist tcp|roc` en los dos y se queda fijo.

## Experimentar

Anota cada prueba en [`EXPERIMENTS.md`](EXPERIMENTS.md). Las perillas están en `config.local.env` de cada lado.
