Descripcion
Aplicacion movil para agentes de campo desarrollada con Flutter, conectada a una API FastAPI y base de datos MySQL. Incluye captura de fotos, ubicacion GPS y seguridad mediante encriptacion.

Instalacion
1. Base de Datos
Importa el archivo e3bd.sql en tu servidor local de MySQL (XAMPP/phpMyAdmin).

2. Backend (FastAPI)
Ve a la carpeta api o api_fastapi.

Ejecuta el servidor con el comando: uvicorn main:app --reload --host 0.0.0.0.

3. Frontend (Flutter)
Ve a la carpeta app_flutter.

Ejecuta el comando "flutter pub get" para descargar las librerias necesarias.

Ejecuta el comando "flutter run" para iniciar la aplicacion en tu dispositivo o emulador.

Credenciales de Prueba
Usuario: ricardo@gmail.com

Contrasena: 12345 (El sistema realiza la validacion mediante hash en el backend)
