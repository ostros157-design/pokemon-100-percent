
import 'package:flutter/material.dart';

class StorageCard extends StatelessWidget {
final String title;
final String subtitle;
final double progress;
final VoidCallback? onTap;
final VoidCallback? onDelete;

const StorageCard({
super.key,
required this.title,
required this.subtitle,
required this.progress,
this.onTap,
this.onDelete,
});

@override
Widget build(BuildContext context) {
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
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: onTap,
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 50,
height: 50,
decoration: BoxDecoration(
color: Colors.blue.withOpacity(0.12),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.save_outlined,
size: 28,
),
),

const SizedBox(width: 14),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
subtitle,
style: TextStyle(
fontSize: 14,
color: Colors.grey.shade600,
),
),
],
),
),

if (onDelete != null)
IconButton(
tooltip: 'Usuń zapis',
icon: const Icon(Icons.delete_outline),
onPressed: onDelete,
),
],
),

const SizedBox(height: 16),

Row(
children: [
Expanded(
child: ClipRRect(
borderRadius: BorderRadius.circular(10),
child: LinearProgressIndicator(
value: safeProgress,
minHeight: 9,
backgroundColor: Colors.grey.shade300,
),
),
),

const SizedBox(width: 12),

Text(
'$percentage%',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
],
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
),
);
}
}
