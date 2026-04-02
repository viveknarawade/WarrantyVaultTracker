import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
Future<String?> uploadToCloudinary(File img, {String? publicId}) async {
  try {
    const cloudName = "dzxiekmtk";
    const uploadPreset = "preset-for-file-upload";

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath('file', img.path));
    request.fields['upload_preset'] = uploadPreset;

    if (publicId != null) {
      request.fields['public_id'] = publicId; // Overwrite old image
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      return json['secure_url'];
    } else {
      log("Cloudinary upload failed: $responseBody");
      return null;
    }
  } catch (e) {
    log("Cloudinary error: $e");
    return null;
  }
}
