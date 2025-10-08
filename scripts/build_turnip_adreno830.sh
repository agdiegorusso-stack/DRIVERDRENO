#!/usr/bin/env bash
set -euo pipefail

# Script di riferimento per compilare Mesa Turnip con supporto Adreno 830.
# Richiede: Python 3, Meson, Ninja, LLVM, libdrm, zlib e cmake.

MESA_SRC_DIR=${MESA_SRC_DIR:-"$HOME/mesa"}
BUILD_DIR=${BUILD_DIR:-"$MESA_SRC_DIR/build-turnip-adreno830"}
INSTALL_DIR=${INSTALL_DIR:-"$BUILD_DIR/install"}
PROFILE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/config/device_profiles/adreno_830.yaml"

if [[ ! -d "$MESA_SRC_DIR" ]]; then
  echo "[ERRORE] Impostare MESA_SRC_DIR alla directory dei sorgenti Mesa" >&2
  exit 1
fi

if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "[ERRORE] Profilo Adreno 830 non trovato: $PROFILE_FILE" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$MESA_SRC_DIR"

meson setup "$BUILD_DIR" \
  --buildtype=release \
  -Dplatforms="drm,android" \
  -Ddri-drivers=[] \
  -Dgallium-drivers=[] \
  -Dvulkan-drivers=freedreno \
  -Dfreedreno-kmds="kgsl,msm" \
  -Dfreedreno-use-kgsl=true \
  -Dfreedreno-kgsl-use-libbacktrace=false \
  -Dfreedreno-adreno830-profile="$PROFILE_FILE"

ninja -C "$BUILD_DIR" install

echo "Build completata. Librerie disponibili in: $INSTALL_DIR"
cat <<INFO
Per installare sul dispositivo:
1. Copiare le librerie Vulkan in /vendor/lib64/hw/.
2. Impostare le variabili d'ambiente consigliate:
   export TU_DEBUG="noconform"
   export TU_AFBC=1
   export MESA_VK_WSI_PRESENT_MODE="mailbox"
3. Riavviare il servizio surfaceflinger.
INFO
