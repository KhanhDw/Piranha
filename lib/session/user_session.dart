class UserSession {
  static String? userId;
  static String? email;

  static void clear() {
    userId = null;
    userName = null;
    email = null;
  }

  static bool get isLoggedIn => userId != null && email != null && userName != null;
  static String? userName;
}
