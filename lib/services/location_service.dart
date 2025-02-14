import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Base URL for the GeoDB Cities API (Updated)
  final String baseUrl = 'https://wft-geo-db.p.rapidapi.com/v1/geo';  // GeoDB API URL

  // Replace with your own GeoDB API key
  final String apiKey = 'f38733b515msh9506e61ebcee24bp16de65jsn5316a194873a';  // Use your actual API key

  // Headers for GeoDB API
  final Map<String, String> headers = {
    'X-RapidAPI-Key': 'f38733b515msh9506e61ebcee24bp16de65jsn5316a194873a',  // Replace with your actual API key
  };

  // Fetch countries
  Future<List<String>> fetchCountries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/countries'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<String> countries = [];

      for (var country in data['data']) {
        countries.add(country['name']);
      }

      return countries;
    } else {
      throw Exception('Failed to load countries');
    }
  }

  // Fetch regions for a specific country
  Future<List<String>> fetchStates(String country) async {
    final response = await http.get(
      Uri.parse('$baseUrl/countries/$country/regions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<String> states = [];

      for (var state in data['data']) {
        states.add(state['name']);
      }

      return states;
    } else {
      throw Exception('Failed to load states');
    }
  }


  // Fetch cities for a specific region
  Future<List<String>> fetchDistricts(String state) async {
    final response = await http.get(
      Uri.parse('$baseUrl/regions/$state/cities'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<String> districts = [];

      for (var district in data['data']) {
        districts.add(district['name']);
      }

      return districts;
    } else {
      throw Exception('Failed to load districts');
    }
  }

}
