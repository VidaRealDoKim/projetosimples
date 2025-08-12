import 'package:flutter/material.dart';

class ReservationCard extends StatelessWidget {
  final String roomName;
  final DateTime startTime;
  final DateTime endTime;

  const ReservationCard({
    super.key,
    required this.roomName,
    required this.startTime,
    required this.endTime,
  });

  String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text(roomName),
        subtitle: Text(
          '${formatDate(startTime)}\n${formatTime(startTime)} - ${formatTime(endTime)}',
        ),
      ),
    );
  }
}
