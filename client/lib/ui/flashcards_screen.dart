import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/verb_model.dart';
import '../providers/app_state.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _index = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final verbs = state.verbs;

    if (verbs.isEmpty) {
      return const Scaffold(body: Center(child: Text('Нет глаголов для тренировки')));
    }

    final verb = verbs[_index % verbs.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Тренировка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _flipped = !_flipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    transitionBuilder: (child, animation) {
                      final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotate,
                        child: child,
                        builder: (context, child) {
                          final isUnder = (ValueKey(_flipped) != child?.key);
                          final value = isUnder ? math.min(rotate.value, math.pi / 2) : rotate.value;
                          return Transform(
                            transform: Matrix4.rotationY(value),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                      );
                    },
                    child: _flipped
                        ? _CardBack(key: const ValueKey(true), verb: verb)
                        : _CardFront(key: const ValueKey(false), verb: verb),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _answer(state, verb, 'learning'),
                    icon: const Icon(Icons.replay),
                    label: const Text('Повторить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _answer(state, verb, 'learned'),
                    icon: const Icon(Icons.check),
                    label: const Text('Знаю'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _answer(AppState state, VerbModel verb, String status) {
    state.markVerb(verb, status);
    setState(() {
      _index += 1;
      _flipped = false;
    });
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({super.key, required this.verb});

  final VerbModel verb;

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      child: Center(
        child: Text(
          verb.infinitive,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.verb});

  final VerbModel verb;

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(verb.translation, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Text('Präteritum: ${verb.preterite}'),
          Text('Partizip II: ${verb.pastParticiple}'),
          Text('Hilfsverb: ${verb.auxiliaryVerb}'),
          const SizedBox(height: 18),
          Text(verb.exampleSentence, textAlign: TextAlign.center),
          Text(verb.exampleTranslation, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460, minHeight: 300),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
