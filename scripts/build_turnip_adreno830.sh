#!/usr/bin/env bash
set -euo pipefail

# Script completo per compilare Mesa Turnip con supporto Adreno 830.
# Richiede che il repository Mesa sia stato clonato (vedi setup_turnip_env.sh).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
PROFILE_FILE="$REPO_ROOT/config/device_profiles/adreno_830.yaml"
PATCH_FILE="$REPO_ROOT/patches/mesa-turnip-adreno830.patch"
ARTIFACTS_DIR="$REPO_ROOT/out/adreno830"

DEFAULT_JOBS=$(command -v nproc >/dev/null 2>&1 && nproc || printf '4')
MESA_SRC_DIR=${MESA_SRC_DIR:-"$HOME/mesa"}
BUILD_DIR=${BUILD_DIR:-"$MESA_SRC_DIR/build-turnip-adreno830"}
INSTALL_ROOT=${INSTALL_ROOT:-"$BUILD_DIR/install-root"}
JOBS=${JOBS:-"$DEFAULT_JOBS"}
FORCE_RECONFIG=false
SKIP_PATCH=false
PACKAGE=true
MESA_REF=""

print_usage() {
  cat <<'USAGE'
Uso: build_turnip_adreno830.sh [OPZIONI]

Opzioni:
  --mesa-dir PATH       Percorso del repository Mesa (default $HOME/mesa o MESA_SRC_DIR)
  --build-dir PATH      Directory di build Meson (default <mesa-dir>/build-turnip-adreno830)
  --install-root PATH   Directory di destinazione per meson install --destdir (default <build-dir>/install-root)
  --mesa-ref REF        Reset del repository Mesa al commit/tag specificato prima della build
  --jobs N              Numero di job paralleli per ninja (default nproc)
  --force-reconfigure   Ricrea la configurazione Meson da zero
  --skip-patch          Non applica la patch (si assume già presente)
  --no-package          Non crea il pacchetto degli artefatti
  -h, --help            Mostra questo messaggio

Esempi:
  ./scripts/build_turnip_adreno830.sh --mesa-dir ~/mesa --mesa-ref mesa-24.1.5
  JOBS=16 ./scripts/build_turnip_adreno830.sh --force-reconfigure
USAGE
}

abspath() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
}

require_file() {
  local file=$1
  local description=$2
  if [[ ! -f "$file" ]]; then
    echo "[ERRORE] $description non trovato: $file" >&2
    exit 1
  fi
}

require_dir() {
  local dir=$1
  local description=$2
  if [[ ! -d "$dir" ]]; then
    echo "[ERRORE] $description non trovato: $dir" >&2
    exit 1
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERRORE] Comando richiesto non disponibile: $1" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mesa-dir)
        MESA_SRC_DIR=$2; shift 2 ;;
      --build-dir)
        BUILD_DIR=$2; shift 2 ;;
      --install-root)
        INSTALL_ROOT=$2; shift 2 ;;
      --mesa-ref)
        MESA_REF=$2; shift 2 ;;
      --jobs)
        JOBS=$2; shift 2 ;;
      --force-reconfigure)
        FORCE_RECONFIG=true; shift ;;
      --skip-patch)
        SKIP_PATCH=true; shift ;;
      --no-package)
        PACKAGE=false; shift ;;
      -h|--help)
        print_usage; exit 0 ;;
      *)
        echo "[ERRORE] Opzione sconosciuta: $1" >&2
        print_usage >&2
        exit 1 ;;
    esac
  done
}

prepare_paths() {
  MESA_SRC_DIR=$(abspath "$MESA_SRC_DIR")
  BUILD_DIR=$(abspath "$BUILD_DIR")
  INSTALL_ROOT=$(abspath "$INSTALL_ROOT")
  mkdir -p "$BUILD_DIR" "$INSTALL_ROOT"
}

check_prerequisites() {
  for cmd in git meson ninja python3 tar; do
    require_command "$cmd"
  done

  require_dir "$MESA_SRC_DIR" "Directory Mesa"
  require_dir "$MESA_SRC_DIR/.git" "Repository Mesa"
  require_file "$PROFILE_FILE" "Profilo Adreno 830"
  require_file "$PATCH_FILE" "Patch Mesa Turnip"
}

reset_repo() {
  [[ -z "$MESA_REF" ]] && return
  echo "[INFO] Reset del repository Mesa alla referenza $MESA_REF" >&2
  git -C "$MESA_SRC_DIR" fetch --all --tags
  git -C "$MESA_SRC_DIR" reset --hard "$MESA_REF"
}

apply_patch() {
  [[ "$SKIP_PATCH" == true ]] && { echo "[INFO] Applicazione patch saltata" >&2; return; }

  echo "[INFO] Applicazione patch Turnip Adreno 830" >&2
  if git -C "$MESA_SRC_DIR" apply --check "$PATCH_FILE"; then
    git -C "$MESA_SRC_DIR" apply "$PATCH_FILE"
  elif git -C "$MESA_SRC_DIR" apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
    echo "[INFO] Patch già applicata" >&2
  else
    echo "[ERRORE] Impossibile applicare la patch automaticamente" >&2
    exit 1
  fi
}

configure_build() {
  local meson_args=(
    "$BUILD_DIR"
    "$MESA_SRC_DIR"
    "--prefix=/usr"
    "--libdir=lib"
    "--buildtype=release"
    "-Dplatforms=drm,android"
    "-Ddri-drivers=[]"
    "-Dgallium-drivers=[]"
    "-Dvulkan-drivers=freedreno"
    "-Dfreedreno-kmds=kgsl,msm"
    "-Dfreedreno-use-kgsl=true"
    "-Dfreedreno-kgsl-use-libbacktrace=false"
    "-Dfreedreno-turnip-android-binary=true"
    "-Dfreedreno-adreno830-profile=$PROFILE_FILE"
    "-Dbuild-tests=false"
  )

  if [[ "$FORCE_RECONFIG" == true && -d "$BUILD_DIR" ]]; then
    echo "[INFO] Pulizia configurazione esistente" >&2
    rm -rf "$BUILD_DIR"
  fi

  if [[ ! -f "$BUILD_DIR/meson-private/coredata.dat" ]]; then
    echo "[INFO] Configurazione Meson" >&2
    meson setup "${meson_args[@]}"
  else
    echo "[INFO] Aggiornamento configurazione Meson" >&2
    meson setup --reconfigure "${meson_args[@]}"
  fi
}

build_and_install() {
  echo "[INFO] Compilazione con ninja (jobs=$JOBS)" >&2
  ninja -C "$BUILD_DIR" -j "$JOBS"
  echo "[INFO] Installazione artefatti" >&2
  meson install -C "$BUILD_DIR" --destdir "$INSTALL_ROOT" --no-rebuild
}

generate_icd() {
  local icd_dir="$ARTIFACTS_DIR/icd"
  mkdir -p "$icd_dir"
  cat >"$icd_dir/freedreno_adreno830_icd.json" <<'JSON'
{
  "file_format_version": "1.0.0",
  "ICD": {
    "library_path": "libvulkan_freedreno.so",
    "api_version": "1.3.280"
  }
}
JSON
}

collect_artifacts() {
  [[ "$PACKAGE" == true ]] || { echo "[INFO] Packaging disabilitato" >&2; return; }

  rm -rf "$ARTIFACTS_DIR"
  mkdir -p "$ARTIFACTS_DIR/lib" "$ARTIFACTS_DIR/profiles"

  local lib_search_paths=(
    "$INSTALL_ROOT/usr/lib"
    "$INSTALL_ROOT/usr/lib64"
    "$INSTALL_ROOT/usr/lib/x86_64-linux-gnu"
    "$INSTALL_ROOT/usr/local/lib"
  )

  local found=false
  for path in "${lib_search_paths[@]}"; do
    if [[ -d "$path" ]]; then
      found=true
      find "$path" -maxdepth 1 -type f -name 'libvulkan_freedreno*.so*' -print0 | \
        while IFS= read -r -d '' lib; do
          cp -av "$lib" "$ARTIFACTS_DIR/lib/" >&2
        done
    fi
  done

  if [[ "$found" == false ]]; then
    echo "[WARN] Nessuna libreria libvulkan_freedreno trovata dentro $INSTALL_ROOT" >&2
  fi

  cp -av "$PROFILE_FILE" "$ARTIFACTS_DIR/profiles/" >&2
  generate_icd
}

package_artifacts() {
  [[ "$PACKAGE" == true ]] || return
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local archive="$REPO_ROOT/out/turnip-adreno830-$timestamp.tar.zst"

  echo "[INFO] Creazione archivio $archive" >&2
  if tar --help 2>&1 | grep -q -- '--zstd'; then
    (cd "$ARTIFACTS_DIR" && tar --zstd -cf "$archive" .)
  else
    (cd "$ARTIFACTS_DIR" && tar -I zstd -cf "$archive" .)
  fi
  echo "[SUCCESS] Archivio creato: $archive" >&2
}

main() {
  parse_args "$@"
  prepare_paths
  check_prerequisites
  reset_repo
  apply_patch
  configure_build
  build_and_install
  collect_artifacts
  package_artifacts

  cat <<MESSAGE
[SUCCESS] Build completata.
Artefatti installati (meson --destdir) in: $INSTALL_ROOT
Pacchetto/artefatti locali in: $ARTIFACTS_DIR

Per installare sul dispositivo Android:
1. Copia le librerie libvulkan_freedreno*.so in /vendor/lib64/hw.
2. Copia il file freedreno_adreno830_icd.json in /vendor/etc/vulkan/icd.d/.
3. Imposta le variabili d'ambiente suggerite in docs/adreno830_turnip_support.md.
4. Riavvia surfaceflinger o l'intero dispositivo.
MESSAGE
}

main "$@"
