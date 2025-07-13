# ✅ SÚPER PROMPT – App Flutter “ReCount Pro” con Firebase + Importación desde DBReCountPro.xlsx

Actúa como un desarrollador experto en Flutter y Firebase. Diseña una aplicación móvil llamada **“ReCount Pro”**, orientada a centros de distribución, que permita a los operadores realizar el **segundo conteo diario de vehículos (VH) despachados)**, registrar novedades si las hay, mostrar métricas diarias, y generar un reporte PDF formal. El backend estará basado completamente en **Firebase (Authentication + Firestore)**. Se usará el archivo **`DBReCountPro.xlsx`** como base de datos inicial para poblar...

---

## 🗂️ CARGA INICIAL DE DATOS (desde `DBReCountPro.xlsx`)

El archivo contiene las siguientes hojas, que se convertirán a colecciones de Firestore:

| Hoja Excel     | Colección Firestore | Campos esperados                                       |
|----------------|---------------------|--------------------------------------------------------|
| SKU            | `sku`               | `sku`, `descripcion`, `unidad`, `categoria`           |
| Flota          | `vh_programados`    | `vh_id`, `placa`, `fecha`, `productos[]`              |
| Auxiliares     | `auxiliares`        | `nombre`, `cedula`, `cargo`, `correo`, `telefono`     |
| Verificadores  | `verificadores`     | `uid`, `nombre`, `correo`, `rol`                      |
| Inventario     | `inventario`        | `sku`, `stock`, `ubicacion`, `fecha_actualizacion`    |

> Esta carga se realizará usando un script en Node.js o Python con `firebase-admin`.

---

## 🔐 AUTENTICACIÓN
- Firebase Authentication (correo + contraseña)
- El verificador 2 inicia sesión con su correo
- Su información se cruza con la colección `verificadores`

---

## 👤 PERFIL DEL VERIFICADOR
- Nombre (extraído de Auth + Firestore)
- VH contados hoy
- % de avance diario (vs VH programados)
- **Errores de despacho del mes**
- Botones: Iniciar segundo conteo | Cerrar sesión | Generar PDF

---

## 📲 FLUJO DE SEGUNDO CONTEO

### Campos:
- Fecha automática
- Verificador
- VH Programado
- Placa
- ¿Novedad? Sí / No

### Si NO hay novedad:
- Registrar VH y placa
- Botón: **Agregar VH**

### Si SÍ hay novedad:
- Tipo: Faltante / Sobrante
- DT, SKU, Descripción
- Alistado vs Físico
- Diferencia (calculada)
- Verificado (primer conteo)
- Armador
- Botón: **Agregar VH**

---

## 🧾 GENERACIÓN DE PDF

- Desde la pantalla de perfil
- Muestra todos los VH verificados del día
- Incluye:
  - Fecha
  - Verificador
  - VH programado, Placa, ¿Novedad?
  - Si hubo novedad: todos los detalles

**Pie de página**:
> _Elaborado automáticamente por ReCount Pro by 3M Technology®_

---

## 🎨 SPLASHSCREEN
- Logo **CD-3M** centrado
- Texto: **ReCount Pro**
- Fondo blanco o degradado índigo–teal
- Duración: 3 segundos

---

## 📁 ESTRUCTURA DE CARPETAS FLUTTER

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── profile/
│   ├── conteo/
│   ├── pdf_generator/
├── models/
├── services/
│   ├── firebase_service.dart
│   ├── firestore_queries.dart
│   └── data_import.dart
```

---

## 💾 TECNOLOGÍAS Y PAQUETES

- Flutter + Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage (opcional)

### Paquetes:
- `cloud_firestore`, `firebase_auth`, `firebase_core`
- `pdf`, `printing`
- `excel`, `firebase-admin` (para importar .xlsx)
- `flutterfire_ui`, `provider` o `flutter_bloc`

---

## 🎯 OBJETIVO

Digitalizar el segundo conteo de VH, registrar novedades detalladas, mostrar métricas diarias para el verificador y generar reportes PDF profesionales. La base de datos se precarga desde `DBReCountPro.xlsx`.

