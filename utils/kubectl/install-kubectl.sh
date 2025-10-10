#!/bin/bash

set -e

# Detectar OS y arquitectura
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Mapear arquitecturas
case $ARCH in
    x86_64|amd64) ARCH="amd64" ;;
    i386|i686) ARCH="386" ;;
    arm64|aarch64) ARCH="arm64" ;;
    armv7l|armv6l) ARCH="arm" ;;
    *) echo "Arquitectura no soportada: $ARCH"; exit 1 ;;
esac

# Mapear sistemas operativos
case $OS in
    linux) PLATFORM="linux" ;;
    darwin) PLATFORM="darwin" ;;
    mingw*|msys*|cygwin*) PLATFORM="windows"; EXT=".exe" ;;
    *) echo "OS no soportado: $OS"; exit 1 ;;
esac

# Obtener última versión
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
URL="https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${PLATFORM}/${ARCH}/kubectl${EXT}"

echo "Descargando kubectl ${VERSION} para ${PLATFORM}/${ARCH}..."
curl -LO "$URL"

# Hacer ejecutable y mover a PATH
chmod +x "kubectl${EXT}"

if [[ "$PLATFORM" == "windows" ]]; then
    echo "Mueve kubectl.exe a un directorio en tu PATH"
else
    sudo mv "kubectl${EXT}" /usr/local/bin/kubectl
    echo "kubectl instalado en /usr/local/bin/kubectl"
fi

kubectl version --client
echo "¡Instalación completada!"
