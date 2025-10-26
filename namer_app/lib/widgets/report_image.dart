import 'dart:convert';
import 'package:flutter/material.dart';

class ReportImage extends StatelessWidget {
  final String? imageBase64;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ReportImage({
    super.key,
    this.imageBase64,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (width != null && width! != double.infinity && width! > 0) ? width! * 0.4 : 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width != null && width! != double.infinity && width! > 0) ? width! * 0.4 : 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageBase64 == null || imageBase64!.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      // Remover el prefijo "data:image/...;base64," si existe
      String base64String = imageBase64!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }

      final bytes = base64Decode(base64String);
      
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error al cargar imagen en ReportImage: $error');
            return _buildErrorPlaceholder(Icons.broken_image_outlined);
          },
        ),
      );
    } catch (e) {
      // Si hay error al decodificar, mostrar placeholder
      print('❌ Error al decodificar base64 en ReportImage: $e');
      return _buildErrorPlaceholder(Icons.error_outline);
    }
  }
}
