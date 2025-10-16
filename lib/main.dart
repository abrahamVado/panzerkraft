//1.- Punto de entrada principal que inicializa la demo completa.
import 'package:flutter/material.dart';

void main() {
  //2.- Ejecuta la aplicación material raíz manteniendo la configuración declarativa.
  runApp(const DemoShowcaseApp());
}

//3.- Widget raíz que configura el tema y el enrutamiento base.
class DemoShowcaseApp extends StatelessWidget {
  const DemoShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    //4.- Define el tema claro con colores contrastantes para la demo.
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC));
    return MaterialApp(
      title: 'Panzerkraft Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            ),
      ),
      home: const DemoHomeScreen(),
    );
  }
}

//5.- Pantalla principal que presenta un resumen rápido de la demo.
class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  //6.- Controla el índice seleccionado para alternar los bloques de contenido.
  int _selectedIndex = 0;

  //7.- Lista de mensajes que se muestran en el panel principal.
  static const List<DemoHighlight> _highlights = <DemoHighlight>[
    DemoHighlight(
      title: 'Explora la experiencia',
      description:
          'La interfaz demuestra componentes Material 3 listos para producción '
          'con colores configurables.',
      icon: Icons.palette,
    ),
    DemoHighlight(
      title: 'Prueba la interacción',
      description:
          'Interactúa con los controles inferiores para alternar las tarjetas '
          'y observar las animaciones suaves.',
      icon: Icons.touch_app,
    ),
    DemoHighlight(
      title: 'Integra tus recursos',
      description:
          'La estructura está lista para conectar servicios o datos reales sin '
          'perder la simplicidad de la demo.',
      icon: Icons.extension,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final highlight = _highlights[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        //8.- Presenta un encabezado claro con acciones relevantes.
        title: const Text('Panzerkraft Demo Ready'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.verified),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: isWide
                ? _WideDemoLayout(highlight: highlight)
                : _CompactDemoLayout(highlight: highlight),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        //9.- Barra de navegación para alternar entre los mensajes destacados.
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'Diseño',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app),
            label: 'Interacción',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: 'Integración',
          ),
        ],
      ),
    );
  }
}

//10.- Modelo simple que encapsula cada mensaje destacado.
class DemoHighlight {
  const DemoHighlight({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

//11.- Disposición compacta para móviles.
class _CompactDemoLayout extends StatelessWidget {
  const _CompactDemoLayout({required this.highlight});

  final DemoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DemoHeader(highlight: highlight),
          const SizedBox(height: 24),
          _DemoDetails(highlight: highlight),
          const SizedBox(height: 24),
          const _DemoFooter(),
        ],
      ),
    );
  }
}

//12.- Disposición amplia para pantallas grandes.
class _WideDemoLayout extends StatelessWidget {
  const _WideDemoLayout({required this.highlight});

  final DemoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _DemoHeader(highlight: highlight),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _DemoDetails(highlight: highlight),
                const SizedBox(height: 32),
                const _DemoFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//13.- Tarjeta principal que sintetiza el mensaje.
class _DemoHeader extends StatelessWidget {
  const _DemoHeader({required this.highlight});

  final DemoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(highlight.icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              highlight.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              highlight.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

//14.- Detalles adicionales con chips ilustrativos.
class _DemoDetails extends StatelessWidget {
  const _DemoDetails({required this.highlight});

  final DemoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles rápidos',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoChip(
              icon: Icons.color_lens,
              label: 'Tema personalizable',
              color: colorScheme.primary,
            ),
            _InfoChip(
              icon: Icons.animation,
              label: 'Animaciones suaves',
              color: colorScheme.secondary,
            ),
            _InfoChip(
              icon: Icons.smartphone,
              label: 'Listo para Android',
              color: colorScheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Descripción seleccionada',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          highlight.description,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

//15.- Pie con instrucciones para continuar la demo.
class _DemoFooter extends StatelessWidget {
  const _DemoFooter();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Siguiente paso',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Sustituye el contenido con tus vistas reales o conecta una API para '
            'convertir esta demo en tu producto final.',
          ),
        ],
      ),
    );
  }
}

//16.- Chip informativo reutilizable.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.18),
        child: Icon(icon, color: color),
      ),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
