import 'dart:typed_data';

/// Modelo para manejar imágenes en todas las plataformas (web y móvil)
class ImageData {
  final Uint8List bytes;
  final String name;

  ImageData({
    required this.bytes,
    required this.name,
  });
}