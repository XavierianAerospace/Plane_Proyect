# Proyecto VTOL Stallion - README Técnico

## 1. Objetivo del proyecto

Este proyecto busca desarrollar un flujo de trabajo en MATLAB, Simulink y SolidWorks para analizar un avión VTOL tipo tricóptero, llamado provisionalmente **VTOL Stallion**.

La idea principal es usar geometría exportada desde SolidWorks en formato DXF y datos de masa en CSV para calcular automáticamente parámetros físicos del avión, como masa total, centro de gravedad, geometría básica y, más adelante, momentos de inercia y parámetros para simulación en Simulink.

El proyecto se está construyendo por etapas. Primero se trabaja con datos manuales y DXF 2D. Después se conectará con SolidWorks de forma más automática y finalmente con simulaciones y hardware real.

---

## 2. Flujo general de trabajo

El flujo actual del proyecto es:

```text
SolidWorks / DXF 2D
        ↓
MATLAB importa geometría DXF
        ↓
MATLAB detecta partes y genera tabla maestra
        ↓
Usuario completa masa_g, z_mm y material en CSV
        ↓
MATLAB lee CSV actualizado
        ↓
MATLAB calcula masa total y centro de gravedad
        ↓
MATLAB genera gráficas y tablas de revisión
        ↓
Más adelante: inercias, aerodinámica, motores y Simulink
```

---

## 3. Estado actual del proyecto

Actualmente el código ya permite:

- Leer un DXF general del avión.
- Leer DXF separados por pieza.
- Crear una tabla maestra con las partes del avión.
- Exportar un CSV base.
- Recuperar datos manuales desde un CSV existente.
- Completar masas de prueba desde MATLAB.
- Calcular masa total.
- Calcular centro de gravedad en X, Y y Z.
- Graficar la distribución de masa.
- Graficar el centro de gravedad.
- Mostrar tablas resumen.
- Guardar resultados en archivos `.mat`, `.csv` y figuras.

---

## 4. Arquitectura de carpetas

La estructura recomendada del proyecto es:

```text
MatLab_Simulaciones/
│
├── Main_Vtol.m
│
├── cad/
│   ├── general_dxf/
│   │   └── VTOL_GENERAL.dxf
│   │
│   ├── estructura_dxf/
│   │   ├── ALA_DER_FIJA.dxf
│   │   ├── ALA_IZQ_FIJA.dxf
│   │   ├── ALERON_DER.dxf
│   │   ├── ALERON_IZQ.dxf
│   │   ├── BOOM_TRASERO.dxf
│   │   ├── COLA_DER_FIJA.dxf
│   │   ├── COLA_IZQ_FIJA.dxf
│   │   ├── ELEVON_COLA_DER.dxf
│   │   ├── ELEVON_COLA_IZQ.dxf
│   │   ├── FUSELAJE.dxf
│   │   ├── FUSELAJE_COLA.dxf
│   │   ├── SOPORTE_MOTOR_DER.dxf
│   │   └── SOPORTE_MOTOR_IZQ.dxf
│   │
│   ├── componentes_dxf/
│   │   ├── BATERIA.dxf
│   │   ├── ELECTRONICA.dxf
│   │   ├── MOTOR_DER.dxf
│   │   ├── MOTOR_IZQ.dxf
│   │   ├── MOTOR_TRASERO.dxf
│   │   ├── SERVO_ALA_DER.dxf
│   │   ├── SERVO_ALA_IZQ.dxf
│   │   ├── SERVO_COLA_DER.dxf
│   │   ├── SERVO_COLA_IZQ.dxf
│   │   ├── SERVO_MOTOR_DER.dxf
│   │   └── SERVO_MOTOR_IZQ.dxf
│   │
│   └── Piezas3D/
│
├── src/
│   ├── config/
│   ├── CAD_2D/
│   ├── geometria/
│   ├── exportacion/
│   ├── masa_CG/
│   ├── aero/
│   ├── propulsion/
│   ├── simulador/
│   └── visualizacion/
│
├── resultados/
│   ├── datos_procesados/
│   └── figuras/
│
├── tests/
│
└── simulink/
```

---

## 5. Archivo principal

El archivo principal del proyecto es:

```text
Main_Vtol.m
```

Este archivo se ejecuta desde la carpeta raíz del proyecto:

```matlab
clear functions
rehash
Main_Vtol
```

El `Main_Vtol.m` coordina todo el flujo:

1. Configura las carpetas del proyecto.
2. Agrega `src/` al path de MATLAB.
3. Selecciona el DXF general.
4. Importa geometría 2D.
5. Procesa geometría general.
6. Importa partes separadas.
7. Crea la tabla maestra.
8. Recupera datos manuales desde CSV.
9. Grafica partes y tablas.
10. Calcula masa total y CG.
11. Guarda resultados.
12. Guarda figuras.

---

## 6. Sistema de coordenadas

El sistema interno usado por el proyecto es:

```text
x = eje longitudinal, desde nariz hacia cola
y = eje lateral, izquierda/derecha
z = eje vertical, arriba/abajo
```

Las unidades principales en el CSV son:

```text
x_mm, y_mm, z_mm → milímetros
masa_g           → gramos
area_mm2         → milímetros cuadrados
```

Para los cálculos físicos, MATLAB convierte internamente a:

```text
x_m, y_m, z_m → metros
masa_kg       → kilogramos
area_m2       → metros cuadrados
```

---

## 7. CSV maestro

El archivo CSV principal es:

```text
resultados/datos_procesados/componentes_vtol_base.csv
```

Este archivo contiene una fila por cada pieza detectada o importada desde DXF.

Columnas principales:

| Columna | Descripción |
|---|---|
| `id_global` | Identificador interno de la pieza |
| `categoria` | Puede ser `estructura` o `componente` |
| `tipo` | Tipo de parte: ala, servo, motor, fuselaje, etc. |
| `nombre` | Nombre de la pieza |
| `x_mm` | Posición longitudinal en mm |
| `y_mm` | Posición lateral en mm |
| `z_mm` | Posición vertical en mm |
| `area_mm2` | Área 2D aproximada |
| `masa_g` | Masa de la pieza en gramos |
| `material` | Material o clasificación física |
| `fuente_posicion` | Origen de la posición |
| `fuente_masa` | Origen de la masa |

Actualmente MATLAB calcula `x_mm` y `y_mm` desde los DXF. La columna `z_mm` se completa manualmente porque el DXF es 2D.

---

## 8. Datos que debe completar el usuario

Después de generar el CSV, el usuario debe completar:

```text
masa_g
z_mm
material
```

Para pruebas de lógica, se pueden usar valores aproximados. No es necesario que sean valores finales del avión.

Ejemplo:

```text
BATERIA       → masa_g = 450, z_mm = -25, material = Bateria
MOTOR_DER     → masa_g = 80,  z_mm = 40,  material = Motor
SERVO_ALA_DER → masa_g = 12,  z_mm = 5,   material = Servo
FUSELAJE      → masa_g = 250, z_mm = 0,   material = PLA
```

---

## 9. Módulos principales del código

### 9.1 `src/config/`

Contiene funciones de configuración del proyecto.

Archivos importantes:

```text
configurar_proyecto_vtol.m
configurar_DXF_vtol.m
```

Responsabilidades:

- Definir rutas del proyecto.
- Crear carpetas si no existen.
- Definir unidades del DXF.
- Definir configuración de lectura y visualización.

---

### 9.2 `src/CAD_2D/`

Contiene funciones para importar y analizar archivos DXF.

Archivos importantes:

```text
seleccionar_archivo_DXF.m
importar_DXF_avion_2D.m
analizar_DXF_avion_2D.m
importar_partes_separadas_DXF.m
```

Responsabilidades:

- Leer archivos DXF ASCII.
- Extraer líneas, círculos, arcos, splines y polilíneas.
- Convertir geometría a coordenadas internas del avión.
- Importar partes separadas desde carpetas.
- Calcular centro geométrico 2D de cada parte.

---

### 9.3 `src/geometria/`

Contiene funciones para procesar geometría general.

Archivos importantes:

```text
procesar_geometria_2D.m
imprimir_resumen_geometria_2D.m
```

Responsabilidades:

- Resumir dimensiones generales del avión.
- Obtener información de geometría 2D.
- Preparar datos para etapas posteriores.

---

### 9.4 `src/exportacion/`

Contiene funciones relacionadas con CSV y tablas.

Archivos importantes:

```text
actualizar_tabla_maestra_desde_csv.m
crear_csv_maestro_vtol.m
```

Responsabilidades:

- Crear o actualizar el CSV maestro.
- Recuperar datos manuales ya escritos por el usuario.
- Evitar perder masas o materiales cuando se vuelve a correr el código.

---

### 9.5 `src/masa_CG/`

Contiene los cálculos físicos iniciales.

Archivos importantes:

```text
calcular_masa_CG_vtol.m
imprimir_resumen_masa_CG_vtol.m
```

Responsabilidades:

- Leer la tabla o CSV.
- Validar columnas obligatorias.
- Convertir unidades.
- Ignorar filas incompletas.
- Calcular masa total.
- Calcular peso total.
- Calcular centro de gravedad.
- Crear resumen de masa por categoría y tipo.

---

### 9.6 `src/visualizacion/`

Contiene funciones para generar figuras y tablas visuales.

Archivos importantes:

```text
graficar_zonas_sobre_silueta_DXF.m
graficar_masa_CG_vtol.m
mostrar_tabla_partes_vtol.m
guardar_figuras_abiertas_vtol.m
```

Responsabilidades:

- Dibujar partes DXF.
- Mostrar distribución de masa.
- Mostrar centro de gravedad.
- Colorear puntos por tipo.
- Mostrar tablas externas para no saturar las gráficas.
- Guardar figuras automáticamente.

---

### 9.7 `tests/`

Contiene scripts de prueba.

Archivo importante:

```text
editar_csv_prueba_masas.m
```

Responsabilidades:

- Llenar el CSV con masas, posiciones `z_mm` y materiales de prueba.
- Probar la lógica sin depender todavía de datos reales.

---

## 10. Cálculos actuales

Actualmente el proyecto calcula:

### 10.1 Masa total

```text
masa_total_g = suma de masa_g
masa_total_kg = masa_total_g / 1000
peso_total_N = masa_total_kg * 9.80665
```

### 10.2 Centro de gravedad

El centro de gravedad se calcula como promedio ponderado por masa:

```text
CG_x = sum(masa_i * x_i) / sum(masa_i)
CG_y = sum(masa_i * y_i) / sum(masa_i)
CG_z = sum(masa_i * z_i) / sum(masa_i)
```

### 10.3 Masa por categoría

Agrupa las partes por:

```text
estructura
componente
```

### 10.4 Masa por tipo

Agrupa las partes por tipos como:

```text
ala
motor
servo
fuselaje
bateria
electronica
cola
boom
superficie_control
```

---

## 11. Visualizaciones actuales

El proyecto genera varias figuras:

1. Partes DXF separadas.
2. Tabla resumen de partes.
3. Distribución de masa y CG en vista superior.
4. Distribución de masa y CG en vista lateral.
5. Masa por categoría.
6. Masa por tipo.
7. Tabla de referencia de puntos.

En las gráficas de masa y CG:

- El tamaño de cada bola representa la masa del componente.
- Como el peso es proporcional a la masa, visualmente también representa qué componente pesa más.
- Los colores separan los puntos según el tipo de pieza.
- El CG total se muestra con un marcador diferente.
- No se escriben nombres dentro de la gráfica para evitar saturación visual.

---

## 12. Qué falta por hacer

Las siguientes etapas pendientes son:

### 12.1 Momentos de inercia aproximados

Calcular:

```text
Ixx
Iyy
Izz
Ixy
Ixz
Iyz
```

Primero se hará una aproximación como masas puntuales usando las posiciones de cada componente respecto al CG.

Más adelante se reemplazará con inercias reales desde SolidWorks 3D.

---

### 12.2 Geometría aerodinámica básica

Calcular:

```text
area alar
cuerda media
MAC aproximada
posición del 25% MAC
posición del CG respecto a la MAC
```

---

### 12.3 Revisión de vuelo horizontal

Calcular:

```text
carga alar
CL de crucero
velocidad de pérdida aproximada
margen respecto a stall
```

---

### 12.4 Revisión de hover

Usar las posiciones de los motores para calcular:

```text
brazo de momento de cada motor respecto al CG
empuje necesario por motor
margen empuje/peso
autoridad de control aproximada
```

---

### 12.5 Parámetros para Simulink

Preparar una estructura con:

```text
masa total
CG
inercias
posición de motores
posición de servos
posición de superficies de control
área alar
MAC
```

Esta estructura será usada por el simulador.

---

### 12.6 Simulador simple de servos

Crear en Simulink un modelo inicial para:

- Probar señales de control.
- Ver movimiento de servos.
- Simular límites de ángulo.
- Conectar luego con superficies de control.

---

### 12.7 Dinámica básica del avión

Agregar modelos simples de:

- Movimiento longitudinal.
- Roll, pitch y yaw.
- Respuesta a motores.
- Respuesta a superficies de control.
- Transición VTOL a vuelo horizontal.

---

### 12.8 Conexión con hardware real

Etapa final del flujo:

- Servos reales.
- Controlador de vuelo.
- Pruebas de banco.
- Validación de señales.

---

## 13. Flujo futuro completo

La ruta general del proyecto es:

```text
1. Exportar CSV desde SolidWorks, aunque sea manual.
2. Leer ese CSV desde MATLAB y reemplazar componentes manuales.
3. Crear macro automática de SolidWorks.
4. Crear simulador simple de servos en Simulink.
5. Agregar dinámica básica del avión.
6. Conectar hardware real para pruebas de banco.
```

---

## 14. Cómo correr el proyecto

Desde MATLAB:

```matlab
cd("C:\ruta\a\MatLab_Simulaciones")
clear functions
rehash
Main_Vtol
```

Para llenar datos de prueba:

```matlab
run("tests/editar_csv_prueba_masas.m")
```

Después correr de nuevo:

```matlab
clear functions
rehash
Main_Vtol
```

---

## 15. Recomendaciones importantes

1. Mantener los nombres de los DXF consistentes.
2. No cambiar manualmente el nombre de columnas del CSV.
3. Cerrar Excel o VS Code antes de que MATLAB escriba el CSV.
4. Mantener el DXF general y los DXF separados con el mismo origen de coordenadas.
5. Usar masas de prueba solo para verificar lógica.
6. Reemplazar las masas por datos reales antes de validar el avión.
7. No usar todavía los resultados como diseño final.
8. Documentar cualquier cambio importante en este README.

---

## 16. Limitaciones actuales

El proyecto todavía tiene varias simplificaciones:

- La geometría viene de DXF 2D, no de un CAD 3D completo.
- `z_mm` se ingresa manualmente.
- Las masas actuales pueden ser de prueba.
- El centro de cada pieza se calcula como centro geométrico 2D aproximado.
- Todavía no se calculan inercias reales.
- Todavía no se calcula estabilidad aerodinámica completa.
- Todavía no hay modelo dinámico completo en Simulink.
- Todavía no hay conexión con hardware real.

---

## 17. Convención de nombres

Para evitar errores, se recomienda usar nombres en mayúscula y sin espacios:

```text
ALA_DER_FIJA
ALA_IZQ_FIJA
ALERON_DER
ALERON_IZQ
FUSELAJE
FUSELAJE_COLA
BOOM_TRASERO
MOTOR_DER
MOTOR_IZQ
MOTOR_TRASERO
SERVO_ALA_DER
SERVO_ALA_IZQ
SERVO_MOTOR_DER
SERVO_MOTOR_IZQ
BATERIA
ELECTRONICA
```

---

## 18. Resumen para alguien nuevo

Este código no es todavía un simulador completo del avión. Es la base para conectar CAD, datos de masa y cálculos físicos iniciales.

La etapa actual responde estas preguntas:

```text
¿Qué partes tiene el avión?
¿Dónde está cada parte?
¿Cuánto pesa cada parte?
¿Cuánto pesa el avión completo?
Dónde queda el centro de gravedad?
Qué partes aportan más masa?
```

Cuando esta base esté validada, se pasará a:

```text
momentos de inercia
aerodinámica básica
motores y hover
parámetros para Simulink
simulación de servos
dinámica básica
hardware real
```
