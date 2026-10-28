import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide.dart';
import '../widgets/guide_step_card.dart';

class GuideScreen extends StatefulWidget {
  final Guide guide;
  /// Optional one-based step number to reveal when opened from a map.
  final int? initialStepNumber;

  const GuideScreen({
    super.key,
    required this.guide,
    this.initialStepNumber,
  });

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final Set<int> completedSteps = {};
  final ScrollController _scrollController = ScrollController();
  late final List<GlobalKey> _stepKeys =
      List<GlobalKey>.generate(widget.guide.steps.length, (_) => GlobalKey());
  bool _isLoadingProgress = true;
  bool _didApplyInitialStep = false;

  String get _progressKey =>
      'guide_progress_${widget.guide.gameId}_${widget.guide.id}';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final savedSteps = preferences.getStringList(_progressKey) ?? const <String>[];
    final restoredSteps = savedSteps
        .map(int.tryParse)
        .whereType<int>()
        .where((index) => index >= 0 && index < widget.guide.steps.length)
        .toSet();

    if (!mounted) return;
    setState(() {
      completedSteps
        ..clear()
        ..addAll(restoredSteps);
      _isLoadingProgress = false;
    });
    _revealInitialStep();
  }

  void _revealInitialStep() {
    if (_didApplyInitialStep) return;
    _didApplyInitialStep = true;
    final requested = widget.initialStepNumber;
    if (requested == null || widget.guide.steps.isEmpty) return;
    final index = (requested - 1).clamp(0, widget.guide.steps.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _stepKeys[index].currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.08,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _progressKey,
      completedSteps.map((index) => index.toString()).toList(),
    );
  }

  double get progress {
    if (widget.guide.steps.isEmpty) {
      return 0;
    }

    return completedSteps.length / widget.guide.steps.length;
  }

  int get completedCount => completedSteps.length;

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: _isLoadingProgress
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: guide.steps.isEmpty
                      ? _buildEmptyGuide()
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          children: List<Widget>.generate(guide.steps.length, (index) {
                            final step = guide.steps[index];

                            return GuideStepCard(
                              key: _stepKeys[index],
                              step: step,
                              completed: completedSteps.contains(index),
                              onChanged: () async {
                                setState(() {
                                  if (completedSteps.contains(index)) {
                                    completedSteps.remove(index);
                                  } else {
                                    completedSteps.add(index);
                                  }
                                });
                                await _saveProgress();
                              },
                            );
                          }),
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
