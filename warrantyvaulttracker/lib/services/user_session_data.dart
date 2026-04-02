import 'package:shared_preferences/shared_preferences.dart';

class UserSessionData {
  static bool isLogin = false;
  static String? uid;
  static String? name;
  static String? email;
  static int totalProducts = 0;
  static bool notificationEnabled = true;

  // Set Session Data
  static Future<void> setUserSessionData({
    required bool loginData,
    required String id,
    required String name,
    required String email,
    required int totalProducts,
    required bool notificationEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLogin', loginData);
    await prefs.setString('id', id);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setInt('totalProducts', totalProducts);
    await prefs.setBool('notificationEnabled', notificationEnabled);

    await getSessionData();
  }

  // Get Session Data
  static Future<void> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();

    isLogin = prefs.getBool("isLogin") ?? false;
    uid = prefs.getString("id");
    name = prefs.getString("name");
    email = prefs.getString("email");
    totalProducts = prefs.getInt("totalProducts") ?? 0;
    notificationEnabled = prefs.getBool("notificationEnabled") ?? true;
  }

  // Clear Session Data (Logout)
  static Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLogin = false;
  }

  static Future<void> incrementTotalProducts() async {
    final prefs = await SharedPreferences.getInstance();
    totalProducts = (totalProducts) + 1;
    await prefs.setInt('totalProducts', totalProducts);
  }

  static Future<void> decrementTotalProducts() async {
    final prefs = await SharedPreferences.getInstance();

    totalProducts = (prefs.getInt("totalProducts") ?? 0) - 1;
    if (totalProducts < 0) totalProducts = 0;

    await prefs.setInt("totalProducts", totalProducts);
  }
}
