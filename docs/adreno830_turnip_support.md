# Supporto Turnip per Adreno 830 su ASUS ROG Phone 9 Pro

Questo documento descrive l'architettura proposta per abilitare il supporto alla GPU **Adreno 830** del dispositivo **ASUS ROG Phone 9 Pro** all'interno del driver open source Turnip (Mesa Vulkan). L'obiettivo principale è assicurare compatibilità e prestazioni per gli emulatori **Eden**, **Citron** e **Benji-SC**.

## Obiettivi
- Identificare le caratteristiche hardware principali della GPU.
- Definire i parametri Turnip necessari (ID GPU, versioni, feature flag).
- Fornire una pipeline di build per compilare Turnip con il nuovo profilo.
- Suggerire impostazioni specifiche per l'esecuzione degli emulatori supportati.

## Panoramica Hardware
| Proprietà | Valore |
|-----------|--------|
| Nome commerciale | Adreno 830 |
| Codename interno | `sage` |
| Architettura | Adreno Gen 8.x |
| Frequenza tipica | 1035 MHz |
| RAM condivisa | 12 GB LPDDR5X |
| Driver proprietario di riferimento | Qualcomm v1.5 |

## Integrazione Turnip
1. Eseguire `scripts/setup_turnip_env.sh [--mesa-dir PATH --mesa-ref TAG]` per configurare le dipendenze e predisporre il checkout Mesa.
2. Compilare con `scripts/build_turnip_adreno830.sh [--force-reconfigure --mesa-ref TAG]` che applica automaticamente la patch `patches/mesa-turnip-adreno830.patch`, configura Meson e avvia `ninja`.
3. Gli artefatti risultanti vengono installati in `<build-dir>/install-root/usr/lib` e copiati (assieme al profilo e al JSON ICD) in `out/adreno830/` con un archivio `turnip-adreno830-*.tar.zst` pronto da distribuire.
4. Configurazione di runtime tramite variabili d'ambiente:
   ```bash
   export TU_DEBUG="noconform"
   export TU_ANISO=16
   export TU_AFBC=1
   export MESA_VK_WSI_PRESENT_MODE="mailbox"
   ```
5. Distribuzione delle librerie compilate in `/vendor/lib64/hw/` sul dispositivo.

## Feature Flag chiave
- **A6xx_UBWC**: abilita la compressione UBWC per ridurre il bandwidth.
- **A7xx_ROBUSTNESS**: estende i controlli di robustezza necessari per Benji-SC.
- **VRS Tier 2**: fondamentale per l'emulatore Citron.
- **Timeline Semaphore**: richiesto da Eden.
- **Descriptor Indexing**: necessario per Citron e Benji-SC.
- **Fragment Density Map**: ottimizza la gestione dello scaling su Eden.

## Patch Mesa/Turnip

La patch `patches/mesa-turnip-adreno830.patch` introduce:

- Un nuovo profilo hardware in `freedreno_dev_info` con i limiti della GPU Adreno 830.
- La definizione del profilo Vulkan `adreno830.json` consumato da Turnip.
- L'instradamento automatico del profilo nel codice `tu_device.c`.

Applicazione manuale:

```bash
cd "$MESA_SRC_DIR"
git apply /percorso/DRIVERDRENO/patches/mesa-turnip-adreno830.patch
```

Per annullare la patch utilizzare `git apply -R /percorso/DRIVERDRENO/patches/mesa-turnip-adreno830.patch` oppure ripristinare il checkout con `git reset --hard`.

## Testing suggerito
| Emulatore | Test | Comando consigliato |
|-----------|------|---------------------|
| Eden | `eden --vk-device-info` | Verifica caricamento driver e timeline semaphore. |
| Citron | `citron --renderer=turnip --benchmark mario` | Stress test grafico con Variable Rate Shading. |
| Benji-SC | `benji-sc --validate --vk` | Validazione API Vulkan e descriptor indexing. |

## Roadmap
1. **Fase 1** – Compilazione iniziale e smoke test (1 giorno).
2. **Fase 2** – Ottimizzazione pipeline grafica (3 giorni).
3. **Fase 3** – Validazione completa su dispositivi reali (5 giorni).

## Troubleshooting
- **FPS instabili**: assicurarsi che il governor della GPU sia impostato su "performance" e che `TU_AFBC=1` sia esportato.
- **Crash in Citron**: controllare il supporto `VK_EXT_descriptor_indexing` nella build (visibile con `vulkaninfo`).
- **Lag audio/video**: sincronizzare i clock degli emulatori con il profilo `ROG-Performance` e verificare la latenza USB.

## Conclusioni
Questa documentazione fornisce i riferimenti necessari per attivare il supporto Adreno 830 in Turnip e garantire la compatibilità con gli emulatori target. Ulteriori ottimizzazioni possono essere apportate dopo i primi cicli di test su hardware reale.
