import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4000';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/v1/tokens/authentication');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['authentication_token']['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userName', user['name']);
      await prefs.setInt('userId', user['id']);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<bool> signUp(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/v1/users');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (response.statusCode == 201) return true;
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Signup failed');
  }

// --- UPDATED: ACTIVATE ACCOUNT (With better error handling) ---
  static Future<void> activateAccount(String token) async {
    final url = Uri.parse('$baseUrl/v1/users/activated');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      return; // Success!
    } else {
      // Parse the error from the backend to see what's wrong
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? "Activation failed with status ${response.statusCode}");
    }
  }

  static Future<String> getQuote() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/quote');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quoteText = data['quote']['q'];
        final author = data['quote']['a'];
        return "\"$quoteText\"\n\n- $author";
      }
      return "Stay positive!";
    } catch (e) {
      return "Keep pushing forward.";
    }
  }

  static Future<List<dynamic>> getMoods() async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/moods');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['moods'] ?? []; 
    } else {
      return []; 
    }
  }

  // --- NEW: Check if user is logged in ---
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // --- NEW: CREATE MOOD (Fixed for your Backend Structure) ---
  static Future<bool> createMood({
    required String title,
    required String description,
    required String emoji,
    required int colorValue,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/moods');

    // Convert the Color Integer to a Hex String (e.g. "0xFF42A5F5")
    final colorString = '0x${colorValue.toRadixString(16).toUpperCase()}';

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': description, // Mapping your description to 'content'
        'emotion': 'General',   // Backend requires this, giving it a default
        'emoji': emoji,
        'color': colorString,   // Sending the color as a string
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create mood: ${response.body}');
    }

    return true;
  }
  // --- NEW: DELETE MOOD ---
  static Future<bool> deleteMood(int id) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/moods/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // --- NEW: UPDATE MOOD ---
  static Future<bool> updateMood({
    required int id,
    required String title,
    required String description,
    required String emoji,
    required int colorValue,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/moods/$id');
    final colorString = '0x${colorValue.toRadixString(16).toUpperCase()}';

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': description,
        'emoji': emoji,
        'color': colorString,
      }),
    );

    return response.statusCode == 200;
  }

// --- UPDATED: UPDATE USER PROFILE ---
  static Future<void> updateUserProfile({String? name, String? email}) async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');

    if (token == null || id == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/users/$id');
    
    final Map<String, dynamic> body = {};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Success! Update local storage immediately
      final data = jsonDecode(response.body);
      final newName = data['user']['name']; // Ensure we get the confirmed name from server
      await prefs.setString('userName', newName);
    } else {
      // Failure! Read the error message from the backend
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? "Failed to update profile (${response.statusCode})");
    }
  }

  // --- NEW: CHANGE PASSWORD ---
  static Future<bool> changePassword(String newPassword) async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');

    if (token == null || id == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/users/$id');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'password': newPassword}),
    );

    return response.statusCode == 200;
  }

  // --- NEW: DELETE USER ACCOUNT ---
  static Future<bool> deleteUserAccount() async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');

    if (token == null || id == null) throw Exception("Not authenticated");

    final url = Uri.parse('$baseUrl/v1/users/$id');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

}