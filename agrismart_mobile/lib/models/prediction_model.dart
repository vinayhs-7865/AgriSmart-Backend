class PredictionModel {
  final Map farmerInput;
  final Map environmentData;
  final Map prediction;
  final Map financialAnalysis;

  PredictionModel({
    required this.farmerInput,
    required this.environmentData,
    required this.prediction,
    required this.financialAnalysis,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      farmerInput: json['farmer_input'],
      environmentData: json['environment_data'],
      prediction: json['prediction'],
      financialAnalysis: json['financial_analysis'],
    );
  }
}
