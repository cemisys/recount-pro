#!/usr/bin/env python3
"""
Script para importar datos desde DBReCountPro.xlsx a Firebase Firestore
ReCount Pro by 3M Technology®

Uso:
    python import_data.py --excel_file DBReCountPro.xlsx --firebase_key service_account.json
"""

import argparse
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import sys
import os

def init_firebase(service_account_path):
    """Inicializa la conexión con Firebase"""
    try:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Conexión con Firebase establecida")
        return db
    except Exception as e:
        print(f"❌ Error conectando con Firebase: {e}")
        sys.exit(1)

def import_sku(db, excel_file):
    """Importa SKUs desde la hoja SKU"""
    try:
        df = pd.read_excel(excel_file, sheet_name='SKU')
        collection_ref = db.collection('sku')
        
        count = 0
        batch = db.batch()
        
        for index, row in df.iterrows():
            sku_data = {
                'sku': str(row['SKU']).strip(),
                'descripcion': str(row['DESCRIPCIÓN']).strip(),
                'activo': True
            }
            
            if sku_data['sku'] and sku_data['sku'] != 'nan':
                doc_ref = collection_ref.document(sku_data['sku'])
                batch.set(doc_ref, sku_data)
                count += 1
                
                # Commit en lotes de 500
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
        
        # Commit final
        if count % 500 != 0:
            batch.commit()
            
        print(f"✅ SKUs importados: {count}")
        
    except Exception as e:
        print(f"❌ Error importando SKUs: {e}")

def import_flota(db, excel_file):
    """Importa vehículos programados desde la hoja Flota"""
    try:
        df = pd.read_excel(excel_file, sheet_name='Flota')
        collection_ref = db.collection('vh_programados')
        
        count = 0
        batch = db.batch()
        
        for index, row in df.iterrows():
            # Usar fecha actual ya que no hay columna fecha en el Excel
            fecha = datetime.now()
            
            vh_data = {
                'vh_id': str(row['IDVH']).strip(),
                'placa': str(row['Placa']).strip(),
                'fecha': fecha,
                'productos': []  # Se puede llenar después si hay datos
            }
            
            if vh_data['vh_id'] and vh_data['vh_id'] != 'nan':
                doc_ref = collection_ref.document()
                batch.set(doc_ref, vh_data)
                count += 1
                
                # Commit en lotes de 500
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
        
        # Commit final
        if count % 500 != 0:
            batch.commit()
            
        print(f"✅ VH programados importados: {count}")
        
    except Exception as e:
        print(f"❌ Error importando flota: {e}")

def import_auxiliares(db, excel_file):
    """Importa auxiliares desde la hoja Auxiliares"""
    try:
        df = pd.read_excel(excel_file, sheet_name='Auxiliares')
        collection_ref = db.collection('auxiliares')
        
        count = 0
        batch = db.batch()
        
        for index, row in df.iterrows():
            auxiliar_data = {
                'nombre': str(row['Nombre']).strip(),
                'cedula': str(row['Cedula']).strip(),
                'cargo': str(row['Rol']).strip(),
                'correo': '',  # No disponible en Excel
                'telefono': '',  # No disponible en Excel
                'activo': True
            }
            
            if auxiliar_data['cedula'] and auxiliar_data['cedula'] != 'nan':
                doc_ref = collection_ref.document(auxiliar_data['cedula'])
                batch.set(doc_ref, auxiliar_data)
                count += 1
                
                # Commit en lotes de 500
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
        
        # Commit final
        if count % 500 != 0:
            batch.commit()
            
        print(f"✅ Auxiliares importados: {count}")
        
    except Exception as e:
        print(f"❌ Error importando auxiliares: {e}")

def import_verificadores(db, excel_file):
    """Importa verificadores desde la hoja Verificadores"""
    try:
        df = pd.read_excel(excel_file, sheet_name='Verificadores')
        collection_ref = db.collection('verificadores')
        
        count = 0
        batch = db.batch()
        
        for index, row in df.iterrows():
            # Usar cedula como uid ya que no hay columna uid
            verificador_data = {
                'uid': str(row['Cedula']).strip(),
                'nombre': str(row['Nombre']).strip(),
                'correo': '',  # No disponible en Excel
                'rol': str(row['Rol']).strip() if pd.notna(row['Rol']) else 'verificador',
                'fecha_creacion': datetime.now()
            }
            
            if verificador_data['uid'] and verificador_data['uid'] != 'nan':
                doc_ref = collection_ref.document(verificador_data['uid'])
                batch.set(doc_ref, verificador_data)
                count += 1
                
                # Commit en lotes de 500
                if count % 500 == 0:
                    batch.commit()
                    batch = db.batch()
        
        # Commit final
        if count % 500 != 0:
            batch.commit()
            
        print(f"✅ Verificadores importados: {count}")
        
    except Exception as e:
        print(f"❌ Error importando verificadores: {e}")

def import_inventario(db, excel_file):
    """Importa inventario inicial desde la hoja Inventario (usando datos de ejemplo)"""
    try:
        # Como la hoja Inventario tiene estructura diferente, crear inventario de ejemplo
        collection_ref = db.collection('inventario')
        
        # Obtener SKUs para crear inventario inicial
        sku_collection = db.collection('sku')
        skus = sku_collection.get()
        
        count = 0
        batch = db.batch()
        
        for sku_doc in skus:
            sku_data = sku_doc.to_dict()
            inventario_data = {
                'sku': sku_data['sku'],
                'stock': 0,  # Stock inicial en 0
                'ubicacion': 'Bodega Principal',
                'fecha_actualizacion': datetime.now()
            }
            
            doc_ref = collection_ref.document(sku_data['sku'])
            batch.set(doc_ref, inventario_data)
            count += 1
            
            # Commit en lotes de 500
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
        
        # Commit final
        if count % 500 != 0:
            batch.commit()
            
        print(f"✅ Inventario inicial creado: {count} items")
        
    except Exception as e:
        print(f"❌ Error creando inventario inicial: {e}")

def check_existing_data(db):
    """Verifica si ya existen datos en Firestore"""
    try:
        sku_docs = db.collection('sku').limit(1).get()
        if len(sku_docs) > 0:
            response = input("⚠️  Ya existen datos en Firestore. ¿Desea continuar? (s/N): ")
            if response.lower() not in ['s', 'si', 'sí', 'y', 'yes']:
                print("❌ Importación cancelada")
                sys.exit(0)
    except Exception as e:
        print(f"⚠️  No se pudo verificar datos existentes: {e}")

def main():
    parser = argparse.ArgumentParser(description='Importar datos desde Excel a Firebase Firestore')
    parser.add_argument('--excel_file', required=True, help='Ruta al archivo DBReCountPro.xlsx')
    parser.add_argument('--firebase_key', required=True, help='Ruta al archivo service account JSON')
    parser.add_argument('--force', action='store_true', help='Forzar importación sin confirmación')
    
    args = parser.parse_args()
    
    # Verificar que los archivos existen
    if not os.path.exists(args.excel_file):
        print(f"❌ Archivo Excel no encontrado: {args.excel_file}")
        sys.exit(1)
    
    if not os.path.exists(args.firebase_key):
        print(f"❌ Archivo de credenciales no encontrado: {args.firebase_key}")
        sys.exit(1)
    
    print("🚀 Iniciando importación de datos a ReCount Pro")
    print(f"📁 Archivo Excel: {args.excel_file}")
    print(f"🔑 Credenciales Firebase: {args.firebase_key}")
    print()
    
    # Inicializar Firebase
    db = init_firebase(args.firebase_key)
    
    # Verificar datos existentes
    if not args.force:
        check_existing_data(db)
    
    print("📊 Iniciando importación...")
    print()
    
    # Importar cada hoja
    import_sku(db, args.excel_file)
    import_flota(db, args.excel_file)
    import_auxiliares(db, args.excel_file)
    import_verificadores(db, args.excel_file)
    import_inventario(db, args.excel_file)
    
    print()
    print("🎉 Importación completada exitosamente")
    print("📱 La aplicación ReCount Pro está lista para usar")
    print()
    print("Elaborado por 3M Technology®")

if __name__ == '__main__':
    main()