# ReCount Pro

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/cemisys/ReCount-Pro/releases/tag/v1.0.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/platform-Web%20%7C%20Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev)

Una aplicación móvil profesional para gestión de inventarios y conteos de vehículos, desarrollada con Flutter y Firebase.

## 🎉 Release v1.0.0 - ¡Primera Release Estable!

**ReCount Pro v1.0.0** marca un hito importante con funcionalidades core completamente implementadas:

### ✨ Nuevas Características v1.0.0
- 🔐 **Sistema de registro automático** por primera vez integrado en login
- 📄 **Generación de PDF multiplataforma** compatible con Web y Móvil
- 👥 **Soporte para 8 verificadores** predefinidos con credenciales automáticas
- 🎨 **Interfaz moderna y responsive** con colores e iconos descriptivos
- ⚡ **Vista previa en tiempo real** de credenciales mientras se escribe
- 🔒 **Autenticación Firebase** robusta con validación completa
- 📱 **Experiencia de usuario optimizada** con feedback visual inmediato

### 👥 Verificadores Soportados
La aplicación incluye soporte nativo para registro automático de:
- MILTON SANTIAGO LLANOS, ESTEIMBER ESCORCIA, DEYMER BENITEZ
- FABIAN RODRIGUEZ, HANNER ARBELAEZ, JHOAN GUITIERREZ
- OSNEIDER DUCON, SAMIR PEREZ

**Formato de credenciales**: `{cédula}@recount.com` / `{cédula}123`

## 🚀 Características Principales

- **Gestión de Conteos**: Sistema completo para realizar conteos de inventario en vehículos
- **Autenticación Segura**: Login con Firebase Authentication
- **Sincronización en Tiempo Real**: Datos sincronizados con Firestore
- **Modo Offline**: Funcionalidad completa sin conexión a internet
- **Múltiples Idiomas**: Soporte para español e inglés
- **Modo Oscuro**: Tema claro y oscuro con detección automática del sistema
- **Analytics**: Monitoreo de uso con Firebase Analytics y Crashlytics
- **Performance Optimizada**: Widgets optimizados y gestión inteligente de memoria

## 📱 Capturas de Pantalla

*[Agregar capturas de pantalla aquí]*

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter 3.24.5** - Framework de desarrollo móvil
- **Dart 3.5.4** - Lenguaje de programación

### Backend y Servicios
- **Firebase Core** - Plataforma de desarrollo
- **Firebase Auth** - Autenticación de usuarios
- **Cloud Firestore** - Base de datos NoSQL
- **Firebase Analytics** - Análisis de uso
- **Firebase Crashlytics** - Reporte de errores
- **Firebase Performance** - Monitoreo de rendimiento

### Gestión de Estado y Arquitectura
- **Provider** - Gestión de estado
- **Shared Preferences** - Almacenamiento local
- **Connectivity Plus** - Detección de conectividad

### UI/UX y Localización
- **Flutter Localizations** - Internacionalización
- **Intl** - Formateo de fechas y números
- **Material Design 3** - Sistema de diseño

## 📋 Requisitos del Sistema

### Desarrollo
- Flutter SDK 3.24.5 o superior
- Dart SDK 3.5.4 o superior
- Android Studio / VS Code
- Git

### Dispositivos Objetivo
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- Archivo DBReCountPro.xlsx con datos iniciales

## 🛠️ Instalación

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd recount_pro
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase

#### 3.1 Crear proyecto en Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto
3. Habilitar Authentication (Email/Password)
4. Crear base de datos Firestore

#### 3.2 Configurar Android
1. Agregar app Android en Firebase Console
2. Descargar `google-services.json`
3. Colocar en `android/app/`
4. Configurar `android/build.gradle` y `android/app/build.gradle`

#### 3.3 Configurar iOS (opcional)
1. Agregar app iOS en Firebase Console
2. Descargar `GoogleService-Info.plist`
3. Colocar en `ios/Runner/`

### 4. Configurar reglas de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios autenticados pueden leer/escribir sus propios datos
    match /verificadores/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conteos - solo el verificador puede crear/leer sus conteos
    match /conteos/{document} {
      allow read, write: if request.auth != null && 
        resource.data.verificador_uid == request.auth.uid;
      allow create: if request.auth != null;
    }
    
    // SKU, auxiliares, inventario - solo lectura para usuarios autenticados
    match /sku/{document} {
      allow read: if request.auth != null;
    }
    
    match /auxiliares/{document} {
      allow read: if request.auth != null;
    }
    
    match /inventario/{document} {
      allow read: if request.auth != null;
    }
    
    // VH programados - solo lectura para usuarios autenticados
    match /vh_programados/{document} {
      allow read: if request.auth != null;
    }
  }
}
```

## 📊 Estructura de Datos

### Colecciones de Firestore

#### `sku`
```json
{
  "sku": "SKU001",
  "descripcion": "Producto ejemplo",
  "unidad": "UN",
  "categoria": "Categoria A"
}
```

#### `vh_programados`
```json
{
  "vh_id": "VH001",
  "placa": "ABC123",
  "fecha": "2024-01-15T00:00:00Z",
  "productos": []
}
```

#### `auxiliares`
```json
{
  "nombre": "Juan Pérez",
  "cedula": "12345678",
  "cargo": "Armador",
  "correo": "juan@empresa.com",
  "telefono": "3001234567",
  "activo": true
}
```

#### `verificadores`
```json
{
  "uid": "firebase_user_uid",
  "nombre": "María García",
  "correo": "maria@empresa.com",
  "rol": "verificador",
  "fecha_creacion": "2024-01-15T10:00:00Z"
}
```

#### `conteos`
```json
{
  "vh_id": "VH001",
  "placa": "ABC123",
  "verificador_uid": "firebase_user_uid",
  "fecha": "2024-01-15T14:30:00Z",
  "tiene_novedad": true,
  "novedades": [
    {
      "tipo": "Faltante",
      "dt": "DT001",
      "sku": "SKU001",
      "descripcion": "Producto faltante",
      "alistado": 10,
      "fisico": 8,
      "diferencia": -2,
      "verificado": 8,
      "armador": "Juan Pérez"
    }
  ]
}
```

## 📁 Importación de Datos

### Formato del archivo DBReCountPro.xlsx

El archivo Excel debe contener las siguientes hojas:

#### Hoja "SKU"
| sku | descripcion | unidad | categoria |
|-----|-------------|--------|-----------|
| SKU001 | Producto 1 | UN | Cat A |

#### Hoja "Flota"
| vh_id | placa | fecha |
|-------|-------|-------|
| VH001 | ABC123 | 15/01/2024 |

#### Hoja "Auxiliares"
| nombre | cedula | cargo | correo | telefono |
|--------|--------|-------|--------|---------|
| Juan Pérez | 12345678 | Armador | juan@empresa.com | 3001234567 |

#### Hoja "Verificadores"
| uid | nombre | correo | rol |
|-----|--------|--------|---------|
| user123 | María García | maria@empresa.com | verificador |

#### Hoja "Inventario"
| sku | stock | ubicacion | fecha_actualizacion |
|-----|-------|-----------|--------------------|
| SKU001 | 100 | A1-B2 | 15/01/2024 |

### Proceso de Importación

1. Colocar el archivo `DBReCountPro.xlsx` en el dispositivo
2. Usar el servicio `DataImportService` para importar los datos
3. Los datos se cargarán automáticamente en Firestore

## 🎨 Temas y Colores

- **Primario**: Índigo (#3F51B5)
- **Secundario**: Teal (#009688)
- **Éxito**: Verde (#38A169)
- **Error**: Rojo (#E53E3E)
- **Fondo**: Gris claro (#F5F5F5)

## 📱 Pantallas Principales

1. **Splash Screen**: Logo CD-3M y carga inicial
2. **Login**: Autenticación con Firebase
3. **Perfil**: Métricas del verificador y acciones principales
4. **Conteo**: Formulario para registrar vehículos y novedades
5. **Generador PDF**: Creación y compartición de reportes

## 🔧 Comandos Útiles

```bash
# Ejecutar en modo debug
flutter run

# Construir APK
flutter build apk

# Construir AAB (para Play Store)
flutter build appbundle

# Limpiar proyecto
flutter clean

# Actualizar dependencias
flutter pub upgrade

# Analizar código
flutter analyze
```

## 📦 Dependencias Principales

- `firebase_core`: Configuración base de Firebase
- `firebase_auth`: Autenticación
- `cloud_firestore`: Base de datos
- `provider`: Gestión de estado
- `pdf`: Generación de documentos PDF
- `printing`: Impresión y compartición de PDF
- `excel`: Lectura de archivos Excel
- `share_plus`: Compartir archivos
- `intl`: Internacionalización y formato de fechas

## 🚀 Despliegue

### Android
1. Configurar firma de la aplicación
2. Construir AAB: `flutter build appbundle`
3. Subir a Google Play Console

### iOS
1. Configurar certificados en Xcode
2. Construir IPA: `flutter build ipa`
3. Subir a App Store Connect

## 🤝 Contribución

1. Fork del proyecto
2. Crear rama para feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit de cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Soporte

Para soporte técnico o consultas:
- Email: soporte@3mtechnology.com
- Documentación: [Wiki del proyecto]

---

**Elaborado por 3M Technology®**

*ReCount Pro - Digitalizando el control de inventarios*