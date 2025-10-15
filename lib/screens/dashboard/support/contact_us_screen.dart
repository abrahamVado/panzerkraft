import 'package:flutter/material.dart';

//1.- ContactUsScreen reúne los canales disponibles para soporte al conductor.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contáctanos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          ListTile(
            leading: Icon(Icons.chat_bubble_outline),
            title: Text('Chat en vivo'),
            subtitle: Text('Conversa con un asesor y recibe ayuda inmediata.'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.phone_forwarded),
            title: Text('Línea de emergencia 24/7'),
            subtitle: Text('+52 55 4000 0000'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('Correo de soporte'),
            subtitle: Text('soporte@panzerkraft.app'),
          ),
        ],
      ),
    );
  }
}
