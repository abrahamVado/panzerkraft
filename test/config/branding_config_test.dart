import 'package:test/test.dart';

import 'package:ubberapp/config/branding_config.dart';

void main() {
  //1.- Agrupamos las validaciones principales del archivo de configuración de marcas.
  group('BrandingConfig', () {
    test('travelHistoryVehicleGallery entrega una lista sanitizada e inmutable', () {
      final gallery = BrandingConfig.travelHistoryVehicleGallery();

      expect(gallery, isNotEmpty);
      expect(gallery.every((asset) => asset.trim().isNotEmpty), isTrue);
      expect(() => gallery.add('nuevo.png'), throwsUnsupportedError);
    });

    test('isRemoteSource detecta rutas HTTP o data URI', () {
      expect(BrandingConfig.isRemoteSource('https://example.com/logo.png'), isTrue);
      expect(BrandingConfig.isRemoteSource('data:image/png;base64,AAA'), isTrue);
      expect(BrandingConfig.isRemoteSource('assets/images/logo.png'), isFalse);
    });
  });
}
