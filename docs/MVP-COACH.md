# PH Power Coach — alcance inicial

## Primera entrega local

- Panel separado en `coach.html`.
- Alta, edición, búsqueda y eliminación de clientes.
- Objetivo, peso, plan, estado, próxima revisión y notas.
- Acceso directo a WhatsApp.
- Indicadores de clientes activos y revisiones próximas.
- Datos locales para validar el flujo sin depender todavía de servicios externos.

## Siguiente conexión

1. Crear proyecto en Supabase.
2. Ejecutar `supabase/schema.sql`.
3. Configurar URL pública y clave `anon` en un archivo de configuración no secreto.
4. Añadir registro e inicio de sesión.
5. Reemplazar el almacenamiento local del panel por las tablas con RLS.
6. Crear invitaciones para que cada cliente active su cuenta.

## Criterio del MVP comercial

Un entrenador debe poder administrar cinco clientes reales durante cuatro semanas, asignarles rutinas, revisar sus registros y comunicarse con ellos sin usar hojas de cálculo para esas tareas.
