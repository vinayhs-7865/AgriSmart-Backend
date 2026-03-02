import 'package:flutter/material.dart';
import '../models/prediction_model.dart';

class PredictionResultWidget extends StatelessWidget {
  final PredictionModel result;

  const PredictionResultWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =============================
        // 1️⃣ MAIN RECOMMENDATION CARD
        // =============================
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "🌾 Recommended Crop",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  result.prediction['recommended_crop'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("ROI: ${result.financialAnalysis['roi_percent']}%"),
                Text(
                  "Expected Profit: ₹${result.financialAnalysis['net_profit']}",
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // =============================
        // 2️⃣ FINANCIAL BREAKDOWN
        // =============================
        ExpansionTile(
          title: const Text("💰 Financial Analysis"),
          children: [
            ListTile(
              title: Text("Price per Quintal"),
              trailing: Text(
                "₹${result.financialAnalysis['price_per_quintal']}",
              ),
            ),
            ListTile(
              title: Text("Yield per Acre"),
              trailing: Text(
                "${result.financialAnalysis['yield_per_acre_quintals']} q",
              ),
            ),
            ListTile(
              title: Text("Total Revenue"),
              trailing: Text(
                "₹${result.financialAnalysis['expected_revenue']}",
              ),
            ),
            ListTile(
              title: Text("Total Cost"),
              trailing: Text("₹${result.financialAnalysis['total_cost']}"),
            ),
          ],
        ),

        // =============================
        // 3️⃣ ENVIRONMENT DATA
        // =============================
        ExpansionTile(
          title: const Text("🌦 Environment Details"),
          children: [
            ListTile(
              title: Text("Temperature"),
              trailing: Text("${result.environmentData['temperature']} °C"),
            ),
            ListTile(
              title: Text("Humidity"),
              trailing: Text("${result.environmentData['humidity']}%"),
            ),
            ListTile(
              title: Text("Soil Moisture"),
              trailing: Text("${result.environmentData['soil_moisture']}%"),
            ),
            ListTile(
              title: Text("NPK Levels"),
              trailing: Text(
                "N:${result.environmentData['calculated_NPK']['N']} "
                "P:${result.environmentData['calculated_NPK']['P']} "
                "K:${result.environmentData['calculated_NPK']['K']}",
              ),
            ),
          ],
        ),

        // =============================
        // 4️⃣ AI EXPLANATION
        // =============================
        Card(
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "🧠 AI Explanation:\n\n"
              "Based on current soil moisture, calculated NPK levels, "
              "season (${result.farmerInput['season']}), and district market prices, "
              "${result.prediction['recommended_crop']} provides the highest ROI "
              "with strong suitability (${result.prediction['suitability_percent']}%). "
              "It fits within your budget and maximizes profit potential.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
