import 'Token.dart';

class TokenWithAmount extends Token {
  final BigInt amount;
  final double? price;

  const TokenWithAmount(
      {required String name,
      required address,
      required iconUrl,
      required symbol,
      required balance,
      required decimals,
      required this.amount,
      required this.price})
      : super(
            name: name,
            address: address,
            iconUrl: iconUrl,
            symbol: symbol,
            balance: balance,
            decimals: decimals);

  static fromJSON(dynamic json) {
    var tkn = Token.fromJSON(json);
    // TODO check why json['amount'] can be null
    var amt = BigInt.parse(json['amount'] != null && json['amount'] != "" ? json['amount'] : "0");
    var price = json['price'] == 'DataProgress_NO_DATA' ? null : json['price'];
    return TokenWithAmount(
        name: tkn.name,
        address: tkn.address,
        iconUrl: tkn.iconUrl,
        symbol: tkn.symbol,
        balance: tkn.balance,
        decimals: tkn.decimals,
        amount: amt,
        price: price);
  }

  Map toJsonSkinny() => {
    'address': address,
    'decimals': decimals,
    'amount': amount.toString(),
  };

  TokenWithAmount setAmount(String newAmount) {
    return TokenWithAmount(
      name: name, 
      address: address, 
      iconUrl: iconUrl, 
      symbol: symbol, 
      balance: balance, 
      decimals: decimals, 
      amount: BigInt.parse(newAmount), 
      price: price
    );
  }
}
