from fastapi import UploadFile,File,FastAPI,Form
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext 
pwd_context = CryptContext(schemes=["md5_crypt"], deprecated="auto")
import shutil
import os
import mysql.connector
import requests

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"]
)

def conectar_bd():
    conexion = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="e3bd"
    )
    return conexion

@app.get("/")
def inicio():
    return {"mensaje": "Api funcionando fuerte y claro"}

@app.get("/probar_bd")
def probar_bd():
    conexion = conectar_bd()
    cursor =conexion.cursor()
    cursor.execute("SELECT 1")
    resultado = cursor.fetchone()
    conexion.close()
    return {"respuesta": resultado}

@app.get("/paquetes")
def obtener_paquetes():
    conexion = conectar_bd() 
    cursor = conexion.cursor(dictionary=True)

    cursor.execute("SELECT * FROM paquetes") 
    paquetes = cursor.fetchall() 

    conexion.close()
    
    return paquetes

@app.post("/login")
def login(correo: str = Form(...), contrasena: str = Form(...)):
    conexion = conectar_bd()
    cursor = conexion.cursor(dictionary=True)

    query = "SELECT * FROM usuarios WHERE correo = %s"
    cursor.execute(query, (correo,))
    usuario = cursor.fetchone()
    conexion.close()
    
    if usuario:
        print(f"Login intentado: {correo} con clave {contrasena}")
        if contrasena == "12345": 
            return {"mensaje": "login correcto", "usuario": usuario}
        else:
            return {"mensaje": "credenciales incorrectas"}
    else:
        return {"mensaje": "credenciales incorrectas"}

@app.post("/entrega")
def guardar_entrega(
    id_paquete: int = Form(...),
    latitud: str = Form(...),
    longitud: str = Form(...),
    foto: UploadFile = File(...)
):

    os.makedirs("uploads", exist_ok=True)

    ruta = f"uploads/{foto.filename}"
    with open(ruta, "wb") as buffer:
        buffer.write(foto.file.read())

    conexion = conectar_bd()
    cursor = conexion.cursor()

    query_entrega = "INSERT INTO entregas (id_paquete, foto, latitud, longitud) VALUES (%s, %s, %s, %s)"
    cursor.execute(query_entrega, (id_paquete, ruta, latitud, longitud))

    query_update = "UPDATE paquetes SET estado = 'Entregado' WHERE id = %s"
    cursor.execute(query_update, (id_paquete,))


    conexion.commit() 
    conexion.close() 

    return {"mensaje": "Entrega registrada y paquete actualizado"}

@app.get("/obtener_direccion")
def obtener_direccion(lat: float, lon: float):
    try:
        url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat}&lon={lon}"
        headers = {"User-Agent": "PaquexpressApp/1.0"} 
        
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            datos = response.json()
            direccion_completa = datos.get("display_name", "Dirección no encontrada")
            return {"direccion": direccion_completa}
        
        return {"direccion": "Error en el servidor de mapas"}
    except Exception as e:
        return {"direccion": f"Error al obtener dirección: {str(e)}"}