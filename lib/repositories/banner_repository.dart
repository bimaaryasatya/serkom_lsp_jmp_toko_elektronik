import '../database/sqlite_helper.dart';
import '../models/banner_model.dart';

class BannerRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<List<BannerModel>> getBanners() async {
    return _sqliteHelper.getBanners();
  }
}
