#!/usr/bin/env bash
set -euo pipefail

# Script per configurare un ambiente di sviluppo Linux completo per Mesa/Turnip.
# Funziona su distribuzioni basate su Debian/Ubuntu e richiede privilegi sudo.

if [[ $(id -u) -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

REQUIRED_PACKAGES=(
  git build-essential python3 python3-pip python3-setuptools
  ninja-build meson cmake pkg-config bison flex
  libx11-dev libxext-dev libxdamage-dev libxfixes-dev
  libxcb-dri3-dev libxcb-present-dev libxcb-sync-dev libxcb1-dev
  libxcb-xfixes0-dev libxcb-glx0-dev libxcb-shm0-dev
  libdrm-dev libxrandr-dev libwayland-dev wayland-protocols
  libexpat1-dev libvulkan-dev libzstd-dev zlib1g-dev
  llvm-dev clang libclang-dev spirv-tools libelf-dev
  libunwind-dev libglvnd-dev
)

update_packages() {
  echo "[INFO] Aggiornamento lista pacchetti" >&2
  $SUDO apt-get update -y
}

install_packages() {
  echo "[INFO] Installazione dipendenze di sistema" >&2
  $SUDO apt-get install -y "${REQUIRED_PACKAGES[@]}"
}

install_python_requirements() {
  echo "[INFO] Aggiornamento strumenti Python" >&2
  python3 -m pip install --user --upgrade pip setuptools mako
}

prepare_source_tree() {
  local mesa_dir=${1:-$HOME/mesa}
  if [[ -d "$mesa_dir/.git" ]]; then
    echo "[INFO] Repository Mesa già presente in $mesa_dir" >&2
    return
  fi
  echo "[INFO] Clonazione Mesa (repo ufficiale)" >&2
  git clone https://gitlab.freedesktop.org/mesa/mesa.git "$mesa_dir"
}

main() {
  update_packages
  install_packages
  install_python_requirements
  prepare_source_tree "$@"
  echo "[SUCCESS] Ambiente di sviluppo pronto. Imposta MESA_SRC_DIR per i passi successivi." >&2
}

main "$@"
