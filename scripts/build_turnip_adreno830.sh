#!/usr/bin/env bash
set -euo pipefail

# Script completo per compilare Mesa Turnip con supporto Adreno 830.
# Richiede che il repository Mesa sia stato clonato (vedi setup_turnip_env.sh).

MESA_SRC_DIR=${MESA_SRC_DIR:-"$HOME/mesa"}
BUILD_DIR=${BUILD_DIR:-"$MESA_SRC_DIR/build-turnip-adreno830"}
INSTALL_DIR=${INSTALL_DIR:-"$BUILD_DIR/install"}
PROFILE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/config/device_profiles/adreno_830.yaml"
PATCH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/patches/mesa-turnip-adreno830.patch"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERRORE] Comando richiesto non trovato: $1" >&2
    exit 1
  fi
}

check_prerequisites() {
  for cmd in git meson ninja python3; do
    need_cmd "$cmd"
  done

  if [[ ! -d "$MESA_SRC_DIR/.git" ]]; then
    echo "[ERRORE] Repository Mesa non trovato in $MESA_SRC_DIR" >&2
    exit 1
  fi

  if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "[ERRORE] Profilo Adreno 830 non trovato: $PROFILE_FILE" >&2
    exit 1
  fi

  if [[ ! -f "$PATCH_FILE" ]]; then
    echo "[ERRORE] Patch Mesa Turnip non trovata: $PATCH_FILE" >&2
    exit 1
  fi
}

apply_patch() {
  echo "[INFO] Applicazione patch Turnip Adreno 830" >&2
  if git -C "$MESA_SRC_DIR" apply --check "$PATCH_FILE"; then
    git -C "$MESA_SRC_DIR" apply "$PATCH_FILE"
  else
    echo "[WARN] Patch non applicabile automaticamente, si assume già presente" >&2
  fi
}

configure_build() {
  mkdir -p "$BUILD_DIR"
  meson setup "$BUILD_DIR" \
    --buildtype=release \
    -Dprefix="$INSTALL_DIR" \
    -Dplatforms="drm,android" \
    -Ddri-drivers=[] \
    -Dgallium-drivers=[] \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds="kgsl,msm" \
    -Dfreedreno-use-kgsl=true \
    -Dfreedreno-kgsl-use-libbacktrace=false \
    -Dfreedreno-turnip-android-binary=true \
    -Dfreedreno-adreno830-profile="$PROFILE_FILE" \
    -Dbuild-tests=false
}

build_and_install() {
  ninja -C "$BUILD_DIR" install
}

print_post_instructions() {
  cat <<INFO
[SUCCESS] Build completata.
Artefatti installati in: $INSTALL_DIR

Per installare sul dispositivo:
1. Copiare libvulkan_freedreno.so e le librerie correlate in /vendor/lib64/hw/.
2. Assicurarsi che l'icd JSON punti al percorso delle librerie appena copiate.
3. Impostare le variabili d'ambiente:
   export TU_DEBUG="noconform"
   export TU_AFBC=1
   export TU_ANISO=16
   export MESA_VK_WSI_PRESENT_MODE="mailbox"
4. Riavviare surfaceflinger o il dispositivo.
INFO
}

main() {
  check_prerequisites
  apply_patch
  configure_build
  build_and_install
  print_post_instructions
}

main "$@"
