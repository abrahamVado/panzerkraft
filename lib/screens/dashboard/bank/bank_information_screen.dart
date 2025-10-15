import 'package:flutter/material.dart';

//1.- BankInformationScreen permite capturar y actualizar datos bancarios del conductor.
class BankInformationScreen extends StatefulWidget {
  const BankInformationScreen({super.key});

  @override
  State<BankInformationScreen> createState() => _BankInformationScreenState();
}

class _BankInformationScreenState extends State<BankInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankController;
  late final TextEditingController _accountController;
  late final TextEditingController _clabeController;

  @override
  void initState() {
    super.initState();
    //2.- Inicializamos los campos con valores de ejemplo para facilitar las pruebas.
    _bankController = TextEditingController(text: 'Banco Andariego');
    _accountController = TextEditingController(text: '1234567890');
    _clabeController = TextEditingController(text: '002010077777777777');
  }

  @override
  void dispose() {
    //3.- Liberamos los controladores al salir de la pantalla.
    _bankController.dispose();
    _accountController.dispose();
    _clabeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información bancaria')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Proporciona los datos bancarios donde recibirás tus depósitos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bankController,
              decoration: const InputDecoration(labelText: 'Banco'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Ingresa un banco válido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'Número de cuenta'),
              validator: (value) => value == null || value.trim().length < 6
                  ? 'Proporciona un número de cuenta válido'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clabeController,
              decoration: const InputDecoration(labelText: 'CLABE'),
              validator: (value) => value == null || value.trim().length != 18
                  ? 'La CLABE debe tener 18 dígitos'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_alt),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  //4.- _submit valida y muestra retroalimentación con un Snackbar descriptivo.
  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu información bancaria fue actualizada.')),
    );
  }
}
