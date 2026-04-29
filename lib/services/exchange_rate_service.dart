import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _endpoint = 'https://api.frankfurter.app/latest';

  static const List<String> supportedCurrencies = [
    'IDR',
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'AUD',
    'CAD',
    'SGD',
    'CHF',
    'CNY',
    'KRW',
    'MYR',
    'THB',
    'PHP',
    'INR',
    'HKD',
    'NZD',
    'SEK',
    'NOK',
    'DKK',
    'PLN',
    'CZK',
    'HUF',
    'TRY',
    'ZAR',
    'BRL',
    'MXN',
    'ILS',
    'RON',
    'BGN',
    'ISK',
  ];

  static Future<Map<String, double>> getIdrRates() async {
    final targetCurrencies = supportedCurrencies
        .where((currency) => currency != 'IDR')
        .join(',');

    final uri = Uri.parse(
      _endpoint,
    ).replace(queryParameters: {'from': 'IDR', 'to': targetCurrencies});

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Data kurs global belum tersedia.');
    }

    final decoded = jsonDecode(response.body);
    final rates = decoded['rates'];

    if (rates is! Map) {
      throw Exception('Format data kurs tidak valid.');
    }

    final result = <String, double>{'IDR': 1};

    for (final currency in supportedCurrencies) {
      if (currency == 'IDR') continue;

      final value = rates[currency];
      if (value is num) {
        result[currency] = value.toDouble();
      }
    }

    return result;
  }
}
