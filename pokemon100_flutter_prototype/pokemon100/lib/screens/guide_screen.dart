import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide.dart';
import '../services/app_appearance.dart';
import '../widgets/pixel_icon.dart';
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
    _markGuideOpened();
    _loadProgress();
  }

  Future<void> _markGuideOpened() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      'guide_opened_${widget.guide.gameId}_${widget.guide.id}',
      true,
    );
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
    final index = (requested - 1).clamp(0, widget.guide.steps.length - 1).toInt();
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

    return ValueListenableBuilder<String>(
      valueListenable: AppAppearance.visualStyle,
      builder: (context, visualStyle, _) {
        final pixel = visualStyle == 'pixel';
        return Scaffold(
          appBar: AppBar(
            title: Text(guide.title),
            shape: pixel
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
          ),
          body: _isLoadingProgress
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildProgressHeader(pixel),
                    Expanded(
                      child: guide.steps.isEmpty
                          ? _buildEmptyGuide()
                          : ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              children: _buildGuideSteps(pixel),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<Widget> _buildGuideSteps(bool pixel) {
    final widgets = <Widget>[];
    String? previousSection;

    for (var index = 0; index < widget.guide.steps.length; index++) {
      final step = widget.guide.steps[index];
      final section = step.section ?? 'Początek przygody i pierwsza odznaka';

      if (section != previousSection) {
        final sectionIndexes = <int>[
          for (var i = 0; i < widget.guide.steps.length; i++)
            if ((widget.guide.steps[i].section ??
                    'Początek przygody i pierwsza odznaka') ==
                section)
              i,
        ];
        final sectionCompleted = sectionIndexes
            .where(completedSteps.contains)
            .length;
        final sectionPercent = sectionIndexes.isEmpty
            ? 0
            : (sectionCompleted * 100 / sectionIndexes.length).round();

        final sectionContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '$sectionCompleted/${sectionIndexes.length} · $sectionPercent%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 2 : 10,
              bottom: 7,
            ),
            child: pixel
                ? Container(
                    decoration: ShapeDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: PixelShapeBorder(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        step: 5,
                      ),
                    ),
                    child: sectionContent,
                  )
                : sectionContent,
          ),
        );
        previousSection = section;
      }

      widgets.add(
        GuideStepCard(
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
        ),
      );
    }

    return widgets;
  }

  Widget _buildProgressHeader(bool pixel) {
    final percent = (progress * 100).round();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pixel) ...[
                    PixelIcon(name: 'book', size: 18, color: colorScheme.primary),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    'Postęp poradnika',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (pixel)
            Container(
              decoration: ShapeDecoration(
                shape: PixelShapeBorder(
                  side: BorderSide(color: colorScheme.outline, width: 1),
                  step: 3,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            '$completedCount / ${widget.guide.steps.length} kroków ukończonych',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
