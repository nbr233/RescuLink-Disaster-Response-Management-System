import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double windspeed;
  final int weatherCode;
  final String description;
  final String icon;
  final double humidity;

  WeatherData({
    required this.temperature,
    required this.windspeed,
    required this.weatherCode,
    required this.description,
    required this.icon,
    required this.humidity,
  });
}

class WeatherService {
  static String _getDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Heavy Rain';
    if (code <= 86) return 'Heavy Snow';
    if (code <= 99) return '⚡ Thunderstorm';
    return 'Unknown';
  }

  static String _getIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '⛈️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }

  Future<WeatherData?> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=relativehumidity_2m'
        '&timezone=auto',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final code = (current['weathercode'] as num).toInt();
        // Get current hour humidity
        final humList = data['hourly']['relativehumidity_2m'] as List;
        final humidity = humList.isNotEmpty ? (humList[0] as num).toDouble() : 60.0;
        return WeatherData(
          temperature: (current['temperature'] as num).toDouble(),
          windspeed: (current['windspeed'] as num).toDouble(),
          weatherCode: code,
          description: _getDescription(code),
          icon: _getIcon(code),
          humidity: humidity,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
