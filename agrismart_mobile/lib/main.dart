import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AgriSmartApp());
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PredictScreen(),
    );
  }
}

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final locationController = TextEditingController();
  final soilController = TextEditingController();
  final waterController = TextEditingController();
  final landController = TextEditingController();
  final budgetController = TextEditingController();

  String result = "";

  Future<void> predict() async {
    final url = Uri.parse(
      "https://agrismart-backend-pmdp.onrender.com/predict",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "location": locationController.text,
        "soil_type": soilController.text,
        "water": waterController.text,
        "land_size": double.parse(landController.text),
        "budget": double.parse(budgetController.text),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result =
            "Crop: ${data['recommended_crop']}\nProfit: ₹${data['profit']}\nROI: ${data['roi_percent']}%";
      });
    } else {
      setState(() {
        result = "Error: ${response.body}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AgriSmart Predictor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: soilController,
              decoration: const InputDecoration(labelText: "Soil Type"),
            ),
            TextField(
              controller: waterController,
              decoration: const InputDecoration(
                labelText: "Water (Low/Medium/High)",
              ),
            ),
            TextField(
              controller: landController,
              decoration: const InputDecoration(labelText: "Land Size (acres)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(labelText: "Budget"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: predict, child: const Text("Predict")),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
