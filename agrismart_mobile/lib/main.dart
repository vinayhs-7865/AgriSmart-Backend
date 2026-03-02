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
  final landController = TextEditingController();
  final budgetController = TextEditingController();

  String? selectedLocation;
  String? selectedSoil;
  String? selectedWater;

  Map<String, dynamic>? result;
  bool isLoading = false;

  // ✅ 31 Karnataka Districts
  final List<String> districts = [
    "Bagalkot","Ballari","Belagavi","Bengaluru Rural","Bengaluru Urban",
    "Bidar","Chamarajanagar","Chikkaballapur","Chikkamagaluru","Chitradurga",
    "Dakshina Kannada","Davanagere","Dharwad","Gadag","Hassan",
    "Haveri","Kalaburagi","Kodagu","Kolar","Koppal",
    "Mandya","Mysuru","Raichur","Ramanagara","Shivamogga",
    "Tumakuru","Udupi","Uttara Kannada","Vijayapura","Yadgir",
    "Vijayanagara"
  ];

  final List<String> soilTypes = [
    "Red Soil",
    "Black Soil",
    "Coastal Alluvial Soil"
  ];

  final List<String> waterLevels = [
    "Low",
    "Moderate",
    "High"
  ];

  Future<void> predict() async {
    if (selectedLocation == null ||
        selectedSoil == null ||
        selectedWater == null ||
        landController.text.isEmpty ||
        budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      result = null;
    });

    final land = double.tryParse(landController.text);
    final budget = double.tryParse(budgetController.text);

    if (land == null || budget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid numeric values")),
      );
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse(
      "https://agrismart-backend-pmdp.onrender.com/predict",
    );

    final requestData = {
      "location": selectedLocation,
      "soil_type": selectedSoil,
      "water": selectedWater,
      "land_size": land,
      "budget": budget,
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
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          result!["error"],
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (result!.containsKey("message")) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          result!["message"],
          style: const TextStyle(color: Colors.orange, fontSize: 16),
        ),
      );
    }

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🌾 Prediction Result",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text("Crop: ${result!["prediction"]["recommended_crop"]}"),
            Text("Category: ${result!["prediction"]["predicted_category"]}"),
            Text("Suitability: ${result!["prediction"]["suitability_percent"]}%"),

            const Divider(height: 25),

            Text("Price/Quintal: ₹${result!["financial_analysis"]["price_per_quintal"]}"),
            Text("Yield/Acre: ${result!["financial_analysis"]["yield_per_acre_quintals"]} quintals"),
            Text("Total Yield: ${result!["financial_analysis"]["total_yield_quintals"]} quintals"),

            const Divider(height: 25),

            Text("Total Cost: ₹${result!["financial_analysis"]["total_cost"]}"),
            Text("Expected Revenue: ₹${result!["financial_analysis"]["expected_revenue"]}"),

            const SizedBox(height: 6),
            Text(
              "Net Profit: ₹${result!["financial_analysis"]["net_profit"]}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "ROI: ${result!["financial_analysis"]["roi_percent"]}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((item) =>
                DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriSmart Predictor"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildDropdown("Location", selectedLocation, districts,
                (val) => setState(() => selectedLocation = val)),

            buildDropdown("Soil Type", selectedSoil, soilTypes,
                (val) => setState(() => selectedSoil = val)),

            buildDropdown("Water Level", selectedWater, waterLevels,
                (val) => setState(() => selectedWater = val)),

            TextField(
              controller: landController,
              decoration: const InputDecoration(
                labelText: "Land Size (acres)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: "Budget",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : predict,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Predict",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            buildResult(),
          ],
        ),
      ),
    );
  }
}