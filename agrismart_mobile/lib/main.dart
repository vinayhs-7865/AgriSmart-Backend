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

  Map<String, dynamic>? result;
  bool isLoading = false;

  Future<void> predict() async {
    setState(() {
      isLoading = true;
      result = null;
    });

    final url = Uri.parse(
      "https://agrismart-backend-pmdp.onrender.com/predict",
    );

    final requestData = {
      "location": locationController.text,
      "soil_type": soilController.text,
      "water": waterController.text,
      "land_size": double.parse(landController.text),
      "budget": double.parse(budgetController.text),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          result = decoded;
        });
      } else {
        setState(() {
          result = {"error": decoded["detail"] ?? "Something went wrong"};
        });
      }
    } catch (e) {
      setState(() {
        result = {"error": "Server connection failed"};
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildResult() {
    if (result == null) return const SizedBox();

    if (result!.containsKey("error")) {
      return Text(
        result!["error"],
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prediction Result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              "🌾 Recommended Crop: ${result!["prediction"]["recommended_crop"]}",
            ),
            Text("📂 Category: ${result!["prediction"]["predicted_category"]}"),
            Text(
              "📊 Suitability: ${result!["prediction"]["suitability_percent"]}%",
            ),
            const Divider(),

            Text(
              "💰 Price/Quintal: ₹${result!["financial_analysis"]["predicted_price_per_quintal"]}",
            ),
            Text(
              "📦 Yield/Acre: ${result!["financial_analysis"]["yield_per_acre_quintals"]} quintals",
            ),
            Text(
              "📦 Total Yield: ${result!["financial_analysis"]["total_yield_quintals"]} quintals",
            ),
            const Divider(),

            Text(
              "💵 Total Cost: ₹${result!["financial_analysis"]["total_cost"]}",
            ),
            Text("💵 Revenue: ₹${result!["financial_analysis"]["revenue"]}"),
            Text(
              "📈 Profit: ₹${result!["financial_analysis"]["profit"]}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "📊 ROI: ${result!["financial_analysis"]["roi_percent"]}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
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
            ElevatedButton(
              onPressed: isLoading ? null : predict,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Predict"),
            ),
            buildResult(),
          ],
        ),
      ),
    );
  }
}
