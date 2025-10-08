# DRIVERDRENO

Repository per la gestione di profili e build script dedicati al driver Turnip su dispositivi basati su GPU Adreno.

## Contenuto
- Documentazione dedicata al supporto Adreno 830 (`docs/adreno830_turnip_support.md`).
- Profilo configurazione per ASUS ROG Phone 9 Pro (`config/device_profiles/adreno_830.yaml`).
- Script di build automatizzato (`scripts/build_turnip_adreno830.sh`).
- Script di predisposizione ambiente (`scripts/setup_turnip_env.sh`).
- Patch Mesa/Turnip per Adreno 830 (`patches/mesa-turnip-adreno830.patch`).

## Utilizzo rapido
1. Eseguire `scripts/setup_turnip_env.sh` per installare le dipendenze e clonare Mesa (supporta le opzioni `--mesa-ref` e `--mesa-dir`).
2. Esportare `MESA_SRC_DIR` se si utilizza un percorso differente da `~/mesa`.
3. Avviare `scripts/build_turnip_adreno830.sh` per applicare la patch, configurare Meson e compilare il driver. Al termine troverai:
   - l'albero di installazione in `<build-dir>/install-root` pronto per il push su dispositivo;
   - un archivio compresso e i file ausiliari in `out/`.
4. Copiare le librerie `libvulkan_freedreno*.so` e il JSON ICD sul dispositivo target seguendo le note in `docs/adreno830_turnip_support.md`.

Le opzioni disponibili sugli script e i flussi di test consigliati sono documentati in `docs/`.
