class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'https://verhuuragenda.nl/api';

  // Connection timeout in milliseconds
  static const int connectTimeout = 30000;

  // Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  // API Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String user = '/user';
  static const String dashboard = '/dashboard';
  static const String accommodations = '/accommodations';
  static const String bookings = '/bookings';
  static const String guests = '/guests';
  static const String calendar = '/calendar';
  static const String payments = '/payments';
  static const String seasons = '/seasons';
  static const String cleaning = '/cleaning';
  static const String maintenance = '/maintenance';
  static const String campaigns = '/campaigns';
  static const String statistics = '/statistics';
  static const String profile = '/profile';
  static const String subscription = '/subscription';
  static const String notifications = '/notifications';
  static const String users = '/users';
}
