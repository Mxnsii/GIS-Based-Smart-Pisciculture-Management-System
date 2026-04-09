import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyANLBtNn6ynJCTdC6-TDkSXpS5ggpXCfxM';
  final response = await http.get(Uri.parse(url));
  print(response.body);
}
