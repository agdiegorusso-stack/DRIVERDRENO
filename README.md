# DRIVERDRENO

Repository per la gestione di profili e build script dedicati al driver Turnip su dispositivi basati su GPU Adreno.

## Contenuto
- Documentazione dedicata al supporto Adreno 830 (`docs/adreno830_turnip_support.md`).
- Profilo configurazione per ASUS ROG Phone 9 Pro (`config/device_profiles/adreno_830.yaml`).
- Script di build automatizzato (`scripts/build_turnip_adreno830.sh`).
- Script di predisposizione ambiente (`scripts/setup_turnip_env.sh`).
- Patch Mesa/Turnip per Adreno 830 (`patches/mesa-turnip-adreno830.patch`).

## Utilizzo rapido
Di seguito un esempio di sessione **completa** su Debian/Ubuntu che crea il driver e produce lo ZIP pronto per gli emulatori:

```bash
# 1. Installazione dipendenze e clonazione Mesa (userà ~/mesa di default)
./scripts/setup_turnip_env.sh

# 2. (Facoltativo) usare una directory differente per Mesa
# ./scripts/setup_turnip_env.sh --mesa-dir "$HOME/src/mesa" --mesa-ref mesa-24.1.5

# 3. Assicurarsi che la build punti al checkout corretto
export MESA_SRC_DIR=${MESA_SRC_DIR:-$HOME/mesa}

# 4. Compilare e creare gli archivi .tar.zst e .zip
./scripts/build_turnip_adreno830.sh

# 5. Individuare lo ZIP più recente generato dallo script
ls -t out/turnip-adreno830-*.zip | head -n1
```

Gli artefatti **non** sono versionati in questo repository: vengono creati solo sulla macchina che esegue lo script e rimangono in locale. Al termine della compilazione troverai:

- l'albero di installazione in `<build-dir>/install-root` pronto per il push su dispositivo;
- archivi `.tar.zst` e `.zip` con driver e profili nominati `turnip-adreno830-YYYYMMDD-HHMMSS.*` in `out/`, insieme alla cartella di staging `out/adreno830/` che contiene le librerie e l'ICD generati.

Per copiare le librerie `libvulkan_freedreno*.so` e il JSON ICD sul dispositivo target segui le note in `docs/adreno830_turnip_support.md`.

Le opzioni disponibili sugli script e i flussi di test consigliati sono documentati in `docs/`.
