# DRIVERDRENO

Repository per la gestione di profili e build script dedicati al driver Turnip su dispositivi basati su GPU Adreno.

## Contenuto
- Documentazione dedicata al supporto Adreno 830 (`docs/adreno830_turnip_support.md`).
- Profilo configurazione per ASUS ROG Phone 9 Pro (`config/device_profiles/adreno_830.yaml`).
- Script di build automatizzato (`scripts/build_turnip_adreno830.sh`).

## Utilizzo rapido
1. Clonare i sorgenti Mesa e impostare `MESA_SRC_DIR`.
2. Eseguire `scripts/build_turnip_adreno830.sh`.
3. Distribuire le librerie risultanti sul dispositivo target.

Per dettagli avanzati consultare la documentazione in `docs/`.
