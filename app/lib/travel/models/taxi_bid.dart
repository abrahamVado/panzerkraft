class TaxiBid {
  TaxiBid({
    required this.id,
    required this.driverName,
    required this.amount,
    required this.etaMinutes,
    required this.rating,
  });

  final String id;
  final String driverName;
  final double amount;
  final int etaMinutes;
  final double rating;
}
