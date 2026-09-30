# 0001 — Despliegue automático tras la publicación

Fecha: 2026-09-30
Estado: aceptada

## Contexto

Las imágenes se publican en GHCR en cada merge a master. Hasta ahora el
despliegue se lanzaba a mano (workflow_dispatch), lo que dejaba la última
etapa dependiendo de que alguien se acordara.

Es un entorno de laboratorio: sin usuarios reales, sin datos de terceros
y con vuelta atrás trivial (cambiar la etiqueta de la imagen y reaplicar).

## Decisión

El despliegue se dispara automáticamente con `workflow_run` cuando el
workflow "Publicar" termina con éxito. No hay aprobación humana.

## Consecuencias

- Cada merge a master llega a producción sin intervención.
- Un fallo que las pruebas no detecten llega también.
- El riesgo se acepta porque no hay usuarios y la vuelta atrás es inmediata.

## Alternativas consideradas

**Mantener la aprobación manual** (GitHub Environments con revisores
obligatorios). Se descarta hoy porque añade fricción sin reducir un riesgo
real en este contexto.

**Cuándo revisar esta decisión:** si la aplicación pasa a tener usuarios
reales o datos que no se puedan perder, se activa el entorno `produccion`
con revisor obligatorio y se vuelve a Entrega Continua.
