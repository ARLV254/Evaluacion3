import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paquexpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0FDF4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D9488),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

// --- PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController correoController = TextEditingController();
  TextEditingController contrasenaController = TextEditingController();

  Future<void> login() async {
    var url = Uri.parse("http://192.168.1.95:8000/login");
    var response = await http.post(url, body: {
      "correo": correoController.text.trim(),
      "contrasena": contrasenaController.text.trim(),
    });

    var data = jsonDecode(response.body);
    
    if (data["mensaje"].toString().toLowerCase().contains("correcto")) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PaquetesScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Respuesta del servidor: ${data["mensaje"]}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2, size: 70, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Paquexpress",
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                  ),
                  Text("S.A. de C.V.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Text("BIENVENIDO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: correoController,
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico",
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF0D9488)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: contrasenaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF0D9488)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 35),
                  
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("INICIAR SESIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaquetesScreen extends StatefulWidget {
  @override
  _PaquetesScreenState createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends State<PaquetesScreen> {
  List paquetes = [];

  Future<void> obtenerPaquetes() async {
    var url = Uri.parse("http://192.168.1.95:8000/paquetes"); 
    var response = await http.get(url);
    setState(() {
      paquetes = jsonDecode(response.body);
    });
  }

  @override
  void initState() {
    super.initState();
    obtenerPaquetes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paquetes Asignados")),
      body: ListView.builder(
        itemCount: paquetes.length,
        itemBuilder: (context, index) {
          bool entregado = paquetes[index]['estado'] == 'Entregado';
          return ListTile(
            leading: Icon(
              entregado ? Icons.mark_as_unread : Icons.inventory_2,
              color: entregado ? Colors.green : const Color(0xFF0D9488),
            ),
            title: Text("Paquete #${paquetes[index]['id']}"),
            subtitle: Text(paquetes[index]['direccion']),
            trailing: Text(entregado ? "ENTREGADO" : "PENDIENTE",
              style: TextStyle(color: entregado ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            onTap: entregado ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetalleScreen(paquete: paquetes[index])),
              ).then((value) => obtenerPaquetes());
            },
          );
        },
      ),
    );
  }
}

class DetalleScreen extends StatefulWidget {
  final Map paquete;
  DetalleScreen({required this.paquete});
  @override
  _DetalleScreenState createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  String latitud = "Presiona el botón";
  String longitud = "Presiona el botón";
  XFile? imagen;
  final picker = ImagePicker();
  String direccionAMostrar = "Presiona el botón para ver la calle";

Future<void> obtenerUbicacion() async {
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    latitud = position.latitude.toString();
    longitud = position.longitude.toString();

    var url = Uri.parse("http://192.168.1.95:8000/obtener_direccion?lat=${position.latitude}&lon=${position.longitude}");
    var response = await http.get(url);
    
    var data = jsonDecode(utf8.decode(response.bodyBytes));

    setState(() {
      direccionAMostrar = data["direccion"]; 
    });
  }
}

  Future<void> seleccionarImagen() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) setState(() => imagen = pickedFile);
  }

  Future<void> enviarEntrega() async {
    if (imagen == null || latitud == "Presiona el botón") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, obtén la ubicación y toma una foto")),
      );
      return;
    }

    var url = Uri.parse("http://192.168.1.95:8000/entrega");
    var request = http.MultipartRequest("POST", url); 

    request.fields["id_paquete"] = widget.paquete["id"].toString();
    request.fields["latitud"] = latitud;
    request.fields["longitud"] = longitud;
    var bytes = await imagen!.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        "foto",
        bytes,
        filename: imagen!.name,
      ),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Paquete entregado con éxito!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar la entrega")),
      );
    }
  }

  Future<void> abrirMapa() async {
  final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$latitud,$longitud";
  final Uri url = Uri.parse(googleMapsUrl);

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No se pudo abrir el mapa")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirmar Entrega")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Destino: ${widget.paquete['direccion']}", style: TextStyle(fontSize: 18)),
            Divider(),
            ElevatedButton.icon(onPressed: obtenerUbicacion, icon: Icon(Icons.location_on), label: Text("Validar mi Ubicación")),
            Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Text(
    direccionAMostrar,
    textAlign: TextAlign.center,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
),
if (latitud != "Presiona el botón") 
  TextButton.icon(
    onPressed: abrirMapa,
    icon: const Icon(Icons.map, color: Colors.blue),
    label: const Text("Ver en Google Maps", style: TextStyle(color: Colors.blue)),
  ),
            SizedBox(height: 20),
            ElevatedButton.icon(onPressed: seleccionarImagen, icon: Icon(Icons.camera_alt), label: Text("Tomar Evidencia")),

            if (imagen != null) 
               kIsWeb 
                ? Image.network(imagen!.path, height: 200) 
                : Image.file(File(imagen!.path), height: 200),

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: enviarEntrega,
              child: Text("PAQUETE ENTREGADO"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}