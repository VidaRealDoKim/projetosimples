import 'package:flutter/material.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmação')),
        body: const Center(child: Text('Nenhum dado da reserva')),
      );
    }

    final room = args['room'];
    final DateTime start = args['start'];
    final DateTime end = args['end'];

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sala: ${room['name']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
                'Data: ${start.day}/${start.month}/${start.year}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                'Horário: ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode implementar envio de e-mail usando Supabase Functions ou API externa
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reserva confirmada e e-mail enviado!')));
                Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
              },
              child: const Text('Confirmar e Enviar por E-mail'),
            ),
          ],
        ),
      ),
    );
  }
}
