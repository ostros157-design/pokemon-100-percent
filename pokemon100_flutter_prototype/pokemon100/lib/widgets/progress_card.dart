
import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
final String title;
final double progress;
final String? description;

const ProgressCard({
super.key,
required this.title,
required this.progress,
this.description,
});

@override
Widget build(BuildContext context) {
// Zabezpieczenie wartości postępu przed wyjściem poza zakres 0.0–1.0.
final double safeProgress = progress.clamp(0.0, 1.0);
final int percentage = (safeProgress * 100).round();

return Card(
margin: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
Text(
'$percentage%',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),

if (description != null) ...[
const SizedBox(height: 6),
Text(
description!,
style: TextStyle(
fontSize: 14,
color: Colors.grey.shade600,
),
),
],

const SizedBox(height: 14),

ClipRRect(
borderRadius: BorderRadius.circular(10),
child: LinearProgressIndicator(
value: safeProgress,
minHeight: 10,
backgroundColor: Colors.grey.shade300,
),
),

const SizedBox(height: 8),

Text(
'$percentage% ukończone',
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade600,
),
),
],
),
),
);
}
}

