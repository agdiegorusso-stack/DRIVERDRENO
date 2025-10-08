# DRIVERDRENO

Repository per la gestione di profili e build script dedicati al driver Turnip su dispositivi basati su GPU Adreno.

## Contenuto
- Documentazione dedicata al supporto Adreno 830 (`docs/adreno830_turnip_support.md`).
- Profilo configurazione per ASUS ROG Phone 9 Pro (`config/device_profiles/adreno_830.yaml`).
- Script di build automatizzato (`scripts/build_turnip_adreno830.sh`).
- Script di predisposizione ambiente (`scripts/setup_turnip_env.sh`).
- Patch Mesa/Turnip per Adreno 830 (`patches/mesa-turnip-adreno830.patch`).

## Utilizzo rapido
1. Eseguire `scripts/setup_turnip_env.sh` per installare le dipendenze e clonare Mesa.
2. Impostare `MESA_SRC_DIR` verso il repository Mesa (default `~/mesa`).
3. Lanciare `scripts/build_turnip_adreno830.sh` per applicare la patch e compilare Turnip.
4. Distribuire le librerie risultanti sul dispositivo target.

Per dettagli avanzati consultare la documentazione in `docs/`.
