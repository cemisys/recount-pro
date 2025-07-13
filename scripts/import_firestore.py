import firebase_admin
from firebase_admin import credentials, firestore
import json

# Inicializar Firebase Admin con tu clave de servicio
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Inicializar cliente Firestore
db = firestore.client()

# Cargar archivo JSON exportado
with open("DBReCountPro_Firestore.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Subir cada colección y documento
for collection_name, documents in data.items():
    print(f"📂 Subiendo colección: {collection_name}")
    collection_ref = db.collection(collection_name)
    
    for doc_id, fields in documents.items():
        try:
            collection_ref.document(doc_id).set(fields)
            print(f"  ✅ Documento {doc_id} subido correctamente.")
        except Exception as e:
            print(f"  ❌ Error subiendo documento {doc_id}: {e}")

print("🎉 ¡Importación completada exitosamente!")
