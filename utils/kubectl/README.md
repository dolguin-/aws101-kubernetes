# Instalador de kubectl

Script multiplataforma para instalar la última versión de kubectl automáticamente.

## Sistemas soportados

- **Linux**: 32-bit (386), 64-bit (amd64), ARM, ARM64
- **macOS**: Intel (amd64), Apple Silicon (arm64)
- **Windows**: 32-bit (386), 64-bit (amd64)

## Uso

```bash
./install-kubectl.sh
```

## Qué hace el script

1. Detecta automáticamente tu sistema operativo y arquitectura
2. Descarga la última versión estable de kubectl
3. Lo instala en `/usr/local/bin/kubectl` (Linux/macOS) o te indica dónde moverlo (Windows)
4. Verifica la instalación

## Requisitos

- `curl` instalado
- Permisos de administrador (sudo) en Linux/macOS
- Conexión a internet

## Nota para Windows

En Windows, después de ejecutar el script, mueve manualmente `kubectl.exe` a un directorio que esté en tu PATH.
