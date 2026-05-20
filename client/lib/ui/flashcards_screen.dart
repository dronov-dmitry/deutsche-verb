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
  String _levelFilter = 'All';
  String _typeFilter = 'All';

  List<VerbModel> _filtered(List<VerbModel> verbs) {
    return verbs.where((v) {
      final matchLevel = _levelFilter == 'All' || v.level == _levelFilter;
      final matchType = _typeFilter == 'All' || v.type == _typeFilter;
      return matchLevel && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final verbs = _filtered(state.verbs);
    final hasVerbs = verbs.isNotEmpty;
    final verb = hasVerbs ? verbs[_index % verbs.length] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Тренировка')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['All', 'A1', 'A2', 'B1', 'B2', 'C1'].map((level) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level, style: const TextStyle(fontSize: 13)),
                    selected: _levelFilter == level,
                    onSelected: (_) => setState(() {
                      _levelFilter = level;
                      _index = 0;
                      _flipped = false;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ...['All', 'weak', 'strong', 'mixed'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type), style: const TextStyle(fontSize: 13)),
                      selected: _typeFilter == type,
                      onSelected: (_) => setState(() {
                        _typeFilter = type;
                        _index = 0;
                        _flipped = false;
                      }),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          if (verb != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    Text('${_index + 1} / ${verbs.length}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Нет глаголов по выбранным фильтрам')),
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'weak':
        return 'Слабые';
      case 'strong':
        return 'Сильные';
      case 'mixed':
        return 'Смешанные';
      default:
        return 'Все';
    }
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
