import 'dart:io';
import 'package:image/image.dart' as img;

Future<File> compressImage(File file) async {
  // Görüntüyü yüklüyoruz
  final image = img.decodeImage(await file.readAsBytes());
  if (image == null) {
    throw Exception("Failed to decode image");
  }

  // Görüntüyü sıkıştırıyoruz
  final compressed = img.encodeJpg(image, quality: 70); // Kaliteyi %70 olarak ayarladık

  // Yeni dosya oluşturup sıkıştırılmış veriyi yazıyoruz
  final compressedFile = File(file.path)..writeAsBytesSync(compressed);
  return compressedFile;
}
