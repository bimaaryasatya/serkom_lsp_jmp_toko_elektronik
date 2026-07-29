import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/banner_model.dart';

class BannerRepository {
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/banners'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => BannerModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
