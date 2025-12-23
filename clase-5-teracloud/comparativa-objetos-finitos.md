# Comparativa: Init Containers vs Jobs vs CronJobs

| Aspecto | Init Container | Job | CronJob |
|---------|---------------|-----|---------|
| **Propósito** | Preparar entorno para la app | Ejecutar tarea única | Ejecutar tareas programadas |
| **Contexto** | Parte de un Pod | Recurso independiente | Crea Jobs automáticamente |
| **Cuándo se ejecuta** | Antes de contenedores principales | Cuando lo ejecutas manualmente | Según programación (cron) |
| **Frecuencia** | Una vez por Pod | Una vez por ejecución | Repetitivo según horario |
| **Ciclo de vida** | Ligado al Pod padre | Independiente | Independiente |
| **Si falla** | Reinicia todo el Pod | Reinicia solo el Job | Crea nuevo Job en siguiente programación |
| **Paralelismo** | Secuencial dentro del Pod | Puede ejecutar múltiples Pods | Cada ejecución puede ser paralela |
| **Persistencia** | Termina con el Pod | Se mantiene hasta limpieza manual | Mantiene historial configurable |

## Casos de uso típicos

### Init Container
- Descargar configuración de S3
- Esperar que DB esté disponible
- Configurar permisos de archivos
- Validar dependencias

### Job
- Migración de base de datos
- Procesamiento batch de archivos
- Análisis de datos único
- Importación de datos

### CronJob
- Backups nocturnos
- Limpieza de logs antiguos
- Reportes semanales
- Sincronización periódica

## Analogía de restaurante
- **Init Container**: Preparar ingredientes antes de cocinar
- **Job**: Lavar platos después del servicio
- **CronJob**: Limpieza diaria programada del restaurante

Todos ejecutan tareas finitas, pero en diferentes momentos y contextos.
