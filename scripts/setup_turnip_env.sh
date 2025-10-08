#!/usr/bin/env bash
set -euo pipefail

# Script per configurare un ambiente di sviluppo Linux completo per Mesa/Turnip.
# Funziona su distribuzioni basate su Debian/Ubuntu e richiede privilegi sudo per
# l'installazione dei pacchetti. Lo script controlla la presenza degli strumenti
# fondamentali, installa le librerie richieste per compilare il driver Turnip e
# prepara un checkout del repository Mesa alla revisione specificata.

print_usage() {
  cat <<'EOF'
Uso: setup_turnip_env.sh [OPZIONI]

Opzioni:
  --mesa-dir PATH         Percorso di destinazione del repository Mesa (default ~/mesa)
  --mesa-ref REF          Branch/tag/commit da clonare (default main)
  --skip-clone            Non clonare/aggiornare Mesa, installa solo le dipendenze
  --apt-proxy URL         Imposta APT a usare il proxy indicato (es. http://proxy:3142)
  -h, --help              Mostra questo messaggio

Esempio:
  ./scripts/setup_turnip_env.sh --mesa-dir ~/src/mesa --mesa-ref mesa-24.1.5
EOF
}

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo apt-get
    return
  fi

  echo "[ERRORE] Distribuzione non supportata: è richiesto apt-get" >&2
  exit 1
}

ensure_non_root_warning() {
  if [[ $(id -u) -eq 0 ]]; then
    SUDO=""
  else
    SUDO="sudo"
  fi
}

set_apt_proxy() {
  local proxy=$1
  [[ -z "$proxy" ]] && return
  echo "[INFO] Configurazione proxy APT: $proxy" >&2
  echo "Acquire::http::Proxy \"$proxy\";" | $SUDO tee /etc/apt/apt.conf.d/99turnip-proxy >/dev/null
}

update_packages() {
  echo "[INFO] Aggiornamento lista pacchetti" >&2
  $SUDO "$PKG_MANAGER" update -y
}

install_packages() {
  local packages=(
    build-essential git wget curl
    python3 python3-pip python3-setuptools python3-wheel python3-mako
    ninja-build meson cmake pkg-config bison flex
    libx11-dev libxext-dev libxdamage-dev libxfixes-dev
    libxcb-dri3-dev libxcb-present-dev libxcb-sync-dev libxcb1-dev
    libxcb-xfixes0-dev libxcb-glx0-dev libxcb-shm0-dev
    libdrm-dev libxrandr-dev libwayland-dev wayland-protocols
    libexpat1-dev libvulkan-dev libzstd-dev zlib1g-dev
    llvm-dev clang libclang-dev spirv-tools libelf-dev
    libunwind-dev libglvnd-dev libxml2-utils zstd
    libxcb-keysyms1-dev libxcb-randr0-dev libxcb-util-dev
  )

  echo "[INFO] Installazione dipendenze di sistema" >&2
  $SUDO "$PKG_MANAGER" install -y "${packages[@]}"
}

install_python_requirements() {
  echo "[INFO] Aggiornamento strumenti Python" >&2
  python3 -m pip install --user --upgrade pip setuptools meson ninja mako
}

prepare_source_tree() {
  local mesa_dir=$1
  local mesa_ref=$2

  if [[ -d "$mesa_dir/.git" ]]; then
    echo "[INFO] Repository Mesa già presente in $mesa_dir" >&2
    git -C "$mesa_dir" fetch --all --tags
    git -C "$mesa_dir" checkout "$mesa_ref"
    git -C "$mesa_dir" pull --ff-only || true
    return
  fi

  echo "[INFO] Clonazione Mesa (repo ufficiale, ref: $mesa_ref)" >&2
  git clone --branch "$mesa_ref" --depth 1 https://gitlab.freedesktop.org/mesa/mesa.git "$mesa_dir"
}

main() {
  local mesa_dir="$HOME/mesa"
  local mesa_ref="main"
  local skip_clone=false
  local apt_proxy=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mesa-dir)
        mesa_dir=$2; shift 2 ;;
      --mesa-ref)
        mesa_ref=$2; shift 2 ;;
      --skip-clone)
        skip_clone=true; shift ;;
      --apt-proxy)
        apt_proxy=$2; shift 2 ;;
      -h|--help)
        print_usage; exit 0 ;;
      *)
        echo "[ERRORE] Opzione sconosciuta: $1" >&2
        print_usage >&2
        exit 1 ;;
    esac
  done

  ensure_non_root_warning
  PKG_MANAGER=$(detect_package_manager)
  set_apt_proxy "$apt_proxy"
  update_packages
  install_packages
  install_python_requirements
  if [[ "$skip_clone" == false ]]; then
    prepare_source_tree "$mesa_dir" "$mesa_ref"
  else
    echo "[INFO] Skip clone richiesto: assicurati che MESA_SRC_DIR punti a un checkout valido" >&2
  fi

  cat <<EOF >&2
[SUCCESS] Ambiente di sviluppo pronto.
- Directory Mesa: $mesa_dir
- Referenza: $mesa_ref
- Ricorda di esportare MESA_SRC_DIR=$mesa_dir prima di compilare il driver.
EOF
}

main "$@"
