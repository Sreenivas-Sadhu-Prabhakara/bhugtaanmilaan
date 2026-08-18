import 'package:flutter/material.dart';

void main() => runApp(const BhugtaanmilaanApp());

/// Bhugtaanmilaan — log each sale's tender through the day, then reconcile the
/// channel totals against the closing counts. Mirrors the Go service.
class BhugtaanmilaanApp extends StatelessWidget {
  const BhugtaanmilaanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bhugtaanmilaan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF3E5E8E), useMaterial3: true),
        home: const HomePage(),
      );
}

class Payment {
  final String channel;
  final double amount;
  Payment(this.channel, this.amount);
}

/// channelTotals sums logged payments by channel.
Map<String, double> channelTotals(List<Payment> ps) {
  final out = {'cash': 0.0, 'upi': 0.0, 'card': 0.0};
  for (final p in ps) {
    out[p.channel] = (out[p.channel] ?? 0) + p.amount;
  }
  return out;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _payments = <Payment>[];
  final _amt = TextEditingController();
  final _cCash = TextEditingController();
  final _cUpi = TextEditingController();
  final _cCard = TextEditingController();

  void _add(String channel) {
    final a = double.tryParse(_amt.text.trim()) ?? 0;
    if (a <= 0) return;
    setState(() {
      _payments.insert(0, Payment(channel, a));
      _amt.clear();
    });
  }

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = channelTotals(_payments);
    String m(double v) => '₹${v.toStringAsFixed(2)}';
    Widget gap(String label, double logged, TextEditingController counted) {
      final g = _n(counted) - logged;
      final shown = counted.text.trim().isEmpty ? '—' : '${g >= 0 ? '+' : ''}${m(g)}';
      return ListTile(
        dense: true,
        title: Text('$label · logged ${m(logged)}'),
        trailing: Text(shown, style: TextStyle(fontWeight: FontWeight.bold,
            color: g.abs() < 1e-9 ? Colors.green : Colors.red)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bhugtaanmilaan · payments'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Log a payment as it happens', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _amt, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount ₹', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _add('cash'), child: const Text('Cash'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => _add('upi'), child: const Text('UPI'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => _add('card'), child: const Text('Card'))),
        ]),
        const Divider(height: 28),
        const Text('At close — enter counted totals', style: TextStyle(fontWeight: FontWeight.w600)),
        Row(children: [
          Expanded(child: _c(_cCash, 'Cash')), const SizedBox(width: 8),
          Expanded(child: _c(_cUpi, 'UPI')), const SizedBox(width: 8),
          Expanded(child: _c(_cCard, 'Card')),
        ]),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(children: [
            gap('Cash', t['cash']!, _cCash),
            gap('UPI', t['upi']!, _cUpi),
            gap('Card', t['card']!, _cCard),
          ]),
        ),
      ]),
    );
  }

  Widget _c(TextEditingController c, String label) => TextField(
        controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      );
}
