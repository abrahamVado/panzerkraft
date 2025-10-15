import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  //1.- Initialize Flutter bindings to make sure plugins are ready before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  //2.- Launch the core application widget that wires providers and navigation.
  runApp(const PanzerkraftApp());
}
