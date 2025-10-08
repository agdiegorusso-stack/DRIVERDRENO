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
1. Aggiunta del profilo nel file `config/device_profiles/adreno_830.yaml`.
2. Aggiornamento del build script (`scripts/build_turnip_adreno830.sh`) per includere le patch richieste.
3. Configurazione di runtime tramite variabili d'ambiente:
   ```bash
   export TU_DEBUG="noconform"
   export TU_ANISO=16
   export TU_AFBC=1
   export MESA_VK_WSI_PRESENT_MODE="mailbox"
   ```
4. Distribuzione delle librerie compilate in `/vendor/lib64/hw/` sul dispositivo.

## Feature Flag chiave
- **A6xx_UBWC**: abilita la compressione UBWC per ridurre il bandwidth.
- **A7xx_ROBUSTNESS**: estende i controlli di robustezza necessari per Benji-SC.
- **VRS Tier 2**: fondamentale per l'emulatore Citron.
- **Timeline Semaphore**: richiesto da Eden.

## Testing suggerito
| Emulatore | Test | Comando consigliato |
|-----------|------|---------------------|
| Eden | `eden --vk-device-info` | Verifica caricamento driver.
| Citron | `citron --renderer=turnip --benchmark mario` | Stress test grafico.
| Benji-SC | `benji-sc --validate --vk` | Validazione API Vulkan.

## Roadmap
1. **Fase 1** – Compilazione iniziale e smoke test (1 giorno).
2. **Fase 2** – Ottimizzazione pipeline grafica (3 giorni).
3. **Fase 3** – Validazione completa su dispositivi reali (5 giorni).

## Troubleshooting
- **FPS instabili**: assicurarsi che il governor della GPU sia impostato su "performance".
- **Crash in Citron**: controllare il supporto `VK_EXT_descriptor_indexing` nella build.
- **Lag audio/video**: sincronizzare i clock degli emulatori con il profilo `ROG-Performance`.

## Conclusioni
Questa documentazione fornisce i riferimenti necessari per attivare il supporto Adreno 830 in Turnip e garantire la compatibilità con gli emulatori target. Ulteriori ottimizzazioni possono essere apportate dopo i primi cicli di test su hardware reale.
