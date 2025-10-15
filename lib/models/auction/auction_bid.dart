//1.- AuctionBid representa una oferta de conductor expresada en moneda local.
class AuctionBid {
  //2.- amount define el valor monetario de la oferta.
  final double amount;

  //3.- AuctionBid es inmutable y se inicializa con un monto positivo.
  const AuctionBid({required this.amount});

  //4.- toString facilita la depuración mostrando el monto con dos decimales.
  @override
  String toString() => 'AuctionBid(amount: ' + amount.toStringAsFixed(2) + ')';

  //5.- == y hashCode permiten comparar ofertas por su valor económico.
  @override
  bool operator ==(Object other) {
    return other is AuctionBid && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}
