#!/bin/bash

# Script para ejecutar todos los tests del proyecto ReCount Pro
# Uso: ./scripts/run_tests.sh [opciones]

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_message $BLUE "=================================================="
    print_message $BLUE "$1"
    print_message $BLUE "=================================================="
    echo
}

print_success() {
    print_message $GREEN "✅ $1"
}

print_error() {
    print_message $RED "❌ $1"
}

print_warning() {
    print_message $YELLOW "⚠️  $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Este script debe ejecutarse desde la raíz del proyecto Flutter"
    exit 1
fi

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado o no está en el PATH"
    exit 1
fi

# Variables de configuración
RUN_UNIT_TESTS=true
RUN_WIDGET_TESTS=true
RUN_INTEGRATION_TESTS=false
GENERATE_COVERAGE=false
GENERATE_MOCKS=false

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_UNIT_TESTS=true
            RUN_WIDGET_TESTS=false
            RUN_INTEGRATION_TESTS=false
            shift
            ;;
        --widget-only)
            RUN_UNIT_TESTS=false
            RUN_WIDGET_TESTS=true
            RUN_INTEGRATION_TESTS=false
            shift
            ;;
        --integration)
            RUN_INTEGRATION_TESTS=true
            shift
            ;;
        --coverage)
            GENERATE_COVERAGE=true
            shift
            ;;
        --generate-mocks)
            GENERATE_MOCKS=true
            shift
            ;;
        --all)
            RUN_UNIT_TESTS=true
            RUN_WIDGET_TESTS=true
            RUN_INTEGRATION_TESTS=true
            GENERATE_COVERAGE=true
            shift
            ;;
        --help)
            echo "Uso: $0 [opciones]"
            echo "Opciones:"
            echo "  --unit-only       Solo ejecutar tests unitarios"
            echo "  --widget-only     Solo ejecutar tests de widgets"
            echo "  --integration     Incluir tests de integración"
            echo "  --coverage        Generar reporte de cobertura"
            echo "  --generate-mocks  Generar mocks antes de ejecutar tests"
            echo "  --all             Ejecutar todos los tests con cobertura"
            echo "  --help            Mostrar esta ayuda"
            exit 0
            ;;
        *)
            print_error "Opción desconocida: $1"
            echo "Use --help para ver las opciones disponibles"
            exit 1
            ;;
    esac
done

print_header "INICIANDO TESTS DE RECOUNT PRO"

# Limpiar y obtener dependencias
print_message $BLUE "🔄 Limpiando y obteniendo dependencias..."
flutter clean
flutter pub get

if [ "$GENERATE_MOCKS" = true ]; then
    print_header "GENERANDO MOCKS"
    if flutter packages pub run build_runner build --delete-conflicting-outputs; then
        print_success "Mocks generados exitosamente"
    else
        print_error "Error al generar mocks"
        exit 1
    fi
fi

# Ejecutar análisis estático
print_header "ANÁLISIS ESTÁTICO"
if flutter analyze; then
    print_success "Análisis estático completado sin errores"
else
    print_error "Errores encontrados en el análisis estático"
    exit 1
fi

# Contador de tests
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para ejecutar tests y contar resultados
run_test_suite() {
    local test_name=$1
    local test_command=$2
    
    print_header "EJECUTANDO $test_name"
    
    if eval $test_command; then
        print_success "$test_name completados exitosamente"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_error "$test_name fallaron"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# Ejecutar tests unitarios
if [ "$RUN_UNIT_TESTS" = true ]; then
    if [ "$GENERATE_COVERAGE" = true ]; then
        run_test_suite "TESTS UNITARIOS (CON COBERTURA)" "flutter test --coverage test/core/ test/models/"
    else
        run_test_suite "TESTS UNITARIOS" "flutter test test/core/ test/models/"
    fi
fi

# Ejecutar tests de widgets
if [ "$RUN_WIDGET_TESTS" = true ]; then
    run_test_suite "TESTS DE WIDGETS" "flutter test test/features/"
fi

# Ejecutar tests de integración
if [ "$RUN_INTEGRATION_TESTS" = true ]; then
    print_warning "Los tests de integración requieren un dispositivo o emulador conectado"
    run_test_suite "TESTS DE INTEGRACIÓN" "flutter test integration_test/"
fi

# Generar reporte de cobertura
if [ "$GENERATE_COVERAGE" = true ] && [ -f "coverage/lcov.info" ]; then
    print_header "GENERANDO REPORTE DE COBERTURA"
    
    # Verificar si genhtml está instalado (para generar HTML)
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        print_success "Reporte HTML generado en coverage/html/index.html"
    else
        print_warning "genhtml no está instalado. Solo se generó coverage/lcov.info"
        print_message $YELLOW "Para instalar genhtml: sudo apt-get install lcov (Ubuntu/Debian)"
    fi
    
    # Mostrar resumen de cobertura
    if command -v lcov &> /dev/null; then
        echo
        print_message $BLUE "RESUMEN DE COBERTURA:"
        lcov --summary coverage/lcov.info
    fi
fi

# Resumen final
print_header "RESUMEN DE RESULTADOS"

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "Todos los tests pasaron exitosamente! ($PASSED_TESTS/$TOTAL_TESTS)"
    echo
    print_message $GREEN "🎉 ¡Excelente trabajo! El código está listo para producción."
else
    print_error "Algunos tests fallaron: $FAILED_TESTS/$TOTAL_TESTS"
    echo
    print_message $RED "🔧 Por favor, revisa y corrige los tests que fallaron antes de continuar."
    exit 1
fi

# Consejos adicionales
echo
print_message $BLUE "💡 CONSEJOS:"
echo "   • Ejecuta los tests regularmente durante el desarrollo"
echo "   • Mantén la cobertura de código por encima del 80%"
echo "   • Escribe tests para nuevas funcionalidades antes de implementarlas"
echo "   • Usa --generate-mocks cuando agregues nuevos servicios"

print_success "Tests completados exitosamente!"
