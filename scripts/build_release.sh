#!/bin/bash

# Script para compilar y preparar release de ReCount Pro
# Uso: ./scripts/build_release.sh [version]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Este script debe ejecutarse desde la raíz del proyecto Flutter"
    exit 1
fi

# Obtener versión
if [ -z "$1" ]; then
    VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    print_warning "No se especificó versión, usando la del pubspec.yaml: $VERSION"
else
    VERSION=$1
    print_status "Usando versión especificada: $VERSION"
fi

# Crear directorio de release
RELEASE_DIR="release/v$VERSION"
mkdir -p "$RELEASE_DIR"

print_status "🧹 Limpiando proyecto..."
flutter clean

print_status "📦 Obteniendo dependencias..."
flutter pub get

print_status "🔍 Analizando código..."
flutter analyze

print_status "🧪 Ejecutando tests..."
flutter test

print_status "🏗️ Compilando APK para Android..."
flutter build apk --release --split-per-abi

print_status "🏗️ Compilando AAB para Google Play..."
flutter build appbundle --release

print_status "🌐 Compilando para Web..."
flutter build web --release

# Copiar archivos compilados
print_status "📁 Copiando archivos compilados..."

# Android APKs
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$RELEASE_DIR/recount-pro-v$VERSION-arm64.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$RELEASE_DIR/recount-pro-v$VERSION-arm32.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk "$RELEASE_DIR/recount-pro-v$VERSION-x64.apk"

# Android Bundle
cp build/app/outputs/bundle/release/app-release.aab "$RELEASE_DIR/recount-pro-v$VERSION.aab"

# Web (comprimir)
cd build/web
zip -r "../../$RELEASE_DIR/recount-pro-web-v$VERSION.zip" .
cd ../..

# Generar checksums
print_status "🔐 Generando checksums..."
cd "$RELEASE_DIR"
sha256sum *.apk *.aab *.zip > checksums.txt
cd ../..

# Generar release notes
print_status "📝 Generando release notes..."
cat > "$RELEASE_DIR/RELEASE_NOTES.md" << EOF
# ReCount Pro v$VERSION

## 📱 Descargas

### Android
- **ARM64 (Recomendado)**: \`recount-pro-v$VERSION-arm64.apk\`
- **ARM32**: \`recount-pro-v$VERSION-arm32.apk\`
- **x64**: \`recount-pro-v$VERSION-x64.apk\`

### Web
- **Aplicación Web**: \`recount-pro-web-v$VERSION.zip\`

### Google Play Store
- **Bundle**: \`recount-pro-v$VERSION.aab\`

## 🔐 Verificación de Integridad
Verifica la integridad de los archivos usando:
\`\`\`bash
sha256sum -c checksums.txt
\`\`\`

## 📋 Novedades en esta versión

### ✨ Nuevas características
- Sistema de actualizaciones automáticas
- Verificación de actualizaciones al iniciar la app
- Configuración de verificación automática
- Mejoras en la interfaz de usuario

### 🐛 Correcciones
- Corrección de errores menores
- Optimización de rendimiento
- Mejoras en la estabilidad

### 🔧 Mejoras técnicas
- Actualización de dependencias
- Optimización del código
- Mejoras en el sistema de logging

## 📥 Instalación

### Android
1. Descarga el APK correspondiente a tu arquitectura
2. Habilita "Fuentes desconocidas" en tu dispositivo
3. Instala el APK
4. ¡Disfruta de ReCount Pro!

### Web
1. Descarga el archivo ZIP
2. Extrae el contenido en tu servidor web
3. Accede a \`index.html\` desde tu navegador

## 🆘 Soporte
Si encuentras algún problema, por favor reporta un issue en GitHub.
EOF

# Mostrar resumen
print_success "✅ Release v$VERSION compilado exitosamente!"
print_status "📁 Archivos generados en: $RELEASE_DIR"
print_status "📋 Archivos incluidos:"
ls -la "$RELEASE_DIR"

print_status "🚀 Próximos pasos:"
echo "1. Revisa los archivos en $RELEASE_DIR"
echo "2. Crea un release en GitHub"
echo "3. Sube los archivos como assets"
echo "4. Publica el release"

print_warning "💡 Tip: Usa 'gh release create v$VERSION $RELEASE_DIR/*' si tienes GitHub CLI instalado"
