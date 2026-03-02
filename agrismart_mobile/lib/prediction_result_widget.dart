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
                  result.prediction.recommendedCrop,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("ROI: ${result.financialAnalysis.roiPercent}%"),
                Text(
                  "Expected Profit: ₹${result.financialAnalysis.netProfit}",
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
              title: const Text("Price per Quintal"),
              trailing: Text(
                "₹${result.financialAnalysis.pricePerQuintal}",
              ),
            ),
            ListTile(
              title: const Text("Yield per Acre"),
              trailing: Text(
                "${result.financialAnalysis.yieldPerAcre} q",
              ),
            ),
            ListTile(
              title: const Text("Total Revenue"),
              trailing: Text(
                "₹${result.financialAnalysis.expectedRevenue}",
              ),
            ),
            ListTile(
              title: const Text("Total Cost"),
              trailing: Text("₹${result.financialAnalysis.totalCost}"),
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
              title: const Text("Temperature"),
              trailing:
                  Text("${result.environmentData.temperature} °C"),
            ),
            ListTile(
              title: const Text("Humidity"),
              trailing:
                  Text("${result.environmentData.humidity}%"),
            ),
            ListTile(
              title: const Text("Soil Moisture"),
              trailing:
                  Text("${result.environmentData.soilMoisture}%"),
            ),
            ListTile(
              title: const Text("NPK Levels"),
              trailing: Text(
                "N:${result.environmentData.calculatedNPK['N']} "
                "P:${result.environmentData.calculatedNPK['P']} "
                "K:${result.environmentData.calculatedNPK['K']}",
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

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
              "season (${result.farmerInput.season}), and district market prices, "
              "${result.prediction.recommendedCrop} provides the highest ROI "
              "with strong suitability (${result.prediction.suitabilityPercent}%). "
              "It fits within your budget and maximizes profit potential.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}