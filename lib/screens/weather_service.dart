import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String apiKey = 'a00ab21aa4b8c995085c1a5ce0e09ece';

  Future<WeatherInfo> getWeather() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw WeatherException('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw WeatherException('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw WeatherException('Location permissions permanently denied');
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Fetch weather
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}'
              '&lon=${position.longitude}&appid=$apiKey&units=metric'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherInfo.fromJson(data);
      } else {
        throw WeatherException('Failed to load weather data');
      }
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException(e.toString());
    }
  }
}

class WeatherInfo {
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  WeatherInfo({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }

  String get weatherIcon {
    // Map OpenWeatherMap icon codes to emoji for simple display
    final iconMap = {
      '01d': '☀️', '01n': '🌙', '02d': '⛅', '02n': '☁️',
      '03d': '☁️', '03n': '☁️', '04d': '☁️', '04n': '☁️',
      '09d': '🌧️', '09n': '🌧️', '10d': '🌦️', '10n': '🌧️',
      '11d': '⛈️', '11n': '⛈️', '13d': '🌨️', '13n': '🌨️',
      '50d': '🌫️', '50n': '🌫️',
    };
    return iconMap[icon] ?? '🌡️';
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
