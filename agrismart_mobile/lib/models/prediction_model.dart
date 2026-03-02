class PredictionModel {
  final FarmerInput farmerInput;
  final EnvironmentData environmentData;
  final PredictionData prediction;
  final FinancialAnalysis financialAnalysis;

  PredictionModel({
    required this.farmerInput,
    required this.environmentData,
    required this.prediction,
    required this.financialAnalysis,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      farmerInput: FarmerInput.fromJson(json['farmer_input']),
      environmentData: EnvironmentData.fromJson(json['environment_data']),
      prediction: PredictionData.fromJson(json['prediction']),
      financialAnalysis:
          FinancialAnalysis.fromJson(json['financial_analysis']),
    );
  }
}

class FarmerInput {
  final String location;
  final String district;
  final String season;
  final String soilType;
  final String waterLevel;
  final double landSizeAcres;
  final double budget;

  FarmerInput({
    required this.location,
    required this.district,
    required this.season,
    required this.soilType,
    required this.waterLevel,
    required this.landSizeAcres,
    required this.budget,
  });

  factory FarmerInput.fromJson(Map<String, dynamic> json) {
    return FarmerInput(
      location: json['location'],
      district: json['district'],
      season: json['season'],
      soilType: json['soil_type'],
      waterLevel: json['water_level'],
      landSizeAcres: json['land_size_acres'].toDouble(),
      budget: json['budget'].toDouble(),
    );
  }
}

class EnvironmentData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final Map<String, dynamic> calculatedNPK;

  EnvironmentData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.calculatedNPK,
  });

  factory EnvironmentData.fromJson(Map<String, dynamic> json) {
    return EnvironmentData(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      soilMoisture: json['soil_moisture'].toDouble(),
      calculatedNPK: json['calculated_NPK'],
    );
  }
}

class PredictionData {
  final String recommendedCrop;
  final String predictedCategory;
  final double suitabilityPercent;

  PredictionData({
    required this.recommendedCrop,
    required this.predictedCategory,
    required this.suitabilityPercent,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      recommendedCrop: json['recommended_crop'],
      predictedCategory: json['predicted_category'],
      suitabilityPercent: json['suitability_percent'].toDouble(),
    );
  }
}

class FinancialAnalysis {
  final double pricePerQuintal;
  final double yieldPerAcre;
  final double totalYield;
  final double totalCost;
  final double expectedRevenue;
  final double netProfit;
  final double roiPercent;

  FinancialAnalysis({
    required this.pricePerQuintal,
    required this.yieldPerAcre,
    required this.totalYield,
    required this.totalCost,
    required this.expectedRevenue,
    required this.netProfit,
    required this.roiPercent,
  });

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysis(
      pricePerQuintal: json['price_per_quintal'].toDouble(),
      yieldPerAcre: json['yield_per_acre_quintals'].toDouble(),
      totalYield: json['total_yield_quintals'].toDouble(),
      totalCost: json['total_cost'].toDouble(),
      expectedRevenue: json['expected_revenue'].toDouble(),
      netProfit: json['net_profit'].toDouble(),
      roiPercent: json['roi_percent'].toDouble(),
    );
  }
}