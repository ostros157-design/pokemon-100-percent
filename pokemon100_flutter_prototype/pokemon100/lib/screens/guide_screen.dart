
import 'package:flutter/material.dart';

import '../models/guide.dart';
import '../widgets/guide_step_card.dart';

class GuideScreen extends StatefulWidget {
final Guide guide;

const GuideScreen({
super.key,
required this.guide,
});

@override
State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
final Set<int> completedSteps = {};

double get progress {
if (widget.guide.steps.isEmpty) {
return 0;
}

return completedSteps.length / widget.guide.steps.length;
}

int get completedCount {
return completedSteps.length;
}

@override
Widget build(BuildContext context) {
final guide = widget.guide;

return Scaffold(
appBar: AppBar(
title: Text(guide.title),
),
body: Column(
children: [
_buildProgressHeader(),

Expanded(
child: guide.steps.isEmpty
? _buildEmptyGuide()
    : ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: guide.steps.length,
itemBuilder: (context, index) {
final step = guide.steps[index];

return GuideStepCard(
step: step,
completed: completedSteps.contains(index),
onChanged: () {
setState(() {
if (completedSteps.contains(index)) {
completedSteps.remove(index);
} else {
completedSteps.add(index);
}
});
},
);
},
),
),
],
),
);
}

Widget _buildProgressHeader() {
final percent = (progress * 100).round();

return Container(
width: double.infinity,
padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
decoration: BoxDecoration(
color: Colors.green.shade50,
border: Border(
bottom: BorderSide(
color: Colors.green.shade100,
),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Postęp poradnika',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
Text(
'$percent%',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),

const SizedBox(height: 10),

ClipRRect(
borderRadius: BorderRadius.circular(10),
child: LinearProgressIndicator(
value: progress,
minHeight: 10,
),
),

const SizedBox(height: 8),

Text(
'$completedCount / ${widget.guide.steps.length} kroków ukończonych',
style: TextStyle(
color: Colors.grey.shade700,
),
),
],
),
);
}

Widget _buildEmptyGuide() {
return const Center(
child: Padding(
padding: EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.menu_book,
size: 64,
),
SizedBox(height: 16),
Text(
'Ten poradnik nie ma jeszcze żadnych kroków.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
),
);
}
}

