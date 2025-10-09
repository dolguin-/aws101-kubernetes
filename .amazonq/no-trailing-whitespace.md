# Instrucción: Evitar Trailing Whitespace

## Regla importante para edición de archivos

**SIEMPRE** evitar trailing whitespace (espacios en blanco al final de las líneas) en todos los archivos editados o creados.

### Qué hacer:
- Eliminar espacios en blanco al final de cada línea
- Asegurar que los archivos terminen con una sola línea vacía
- Verificar que no haya espacios o tabs innecesarios al final

### Por qué es importante:
- Los pre-commit hooks del repositorio fallan con trailing whitespace
- Mantiene la consistencia del código
- Evita commits adicionales para corregir whitespace

### Aplicación:
Esta regla se aplica a TODOS los archivos de texto:
- Archivos de código (.py, .js, .go, etc.)
- Archivos de configuración (.yaml, .json, .toml, etc.)
- Documentación (.md, .txt, etc.)
- Scripts (.sh, .bat, etc.)
