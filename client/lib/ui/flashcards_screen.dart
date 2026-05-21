import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../data/models/verb_model.dart';
import '../providers/app_state.dart';
import '../strings.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _index = 0;
  bool _flipped = false;
  List<String> _levelFilters = [];
  List<String> _typeFilters = [];

  List<VerbModel> _filtered(List<VerbModel> verbs) {
    return verbs.where((v) {
      final matchLevel = _levelFilters.isEmpty || _levelFilters.contains(v.level);
      final matchType = _typeFilters.isEmpty || _typeFilters.contains(v.type);
      return matchLevel && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.locale;
    final verbs = _filtered(state.verbs);
    final hasVerbs = verbs.isNotEmpty;
    final verb = hasVerbs ? verbs[_index % verbs.length] : null;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.of('training', loc))),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['All', 'A1', 'A2', 'B1', 'B2', 'C1'].map((level) {
                final isAll = level == 'All';
                final selected = isAll ? _levelFilters.isEmpty : _levelFilters.contains(level);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(isAll ? Strings.of('all', loc) : level, style: const TextStyle(fontSize: 13)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (isAll) {
                        _levelFilters = [];
                      } else if (selected) {
                        _levelFilters.remove(level);
                      } else {
                        _levelFilters.add(level);
                      }
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
                  final isAll = type == 'All';
                  final selected = isAll ? _typeFilters.isEmpty : _typeFilters.contains(type);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type, loc), style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        if (isAll) {
                          _typeFilters = [];
                        } else if (selected) {
                          _typeFilters.remove(type);
                        } else {
                          _typeFilters.add(type);
                        }
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
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity == null) return;
                            if (details.primaryVelocity! > 400) {
                              setState(() {
                                _index--;
                                if (_index < 0) _index = 0;
                                _flipped = false;
                              });
                            } else if (details.primaryVelocity! < -400) {
                              setState(() {
                                _index++;
                                _flipped = false;
                              });
                            }
                          },
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
                                ? _CardBack(key: const ValueKey(true), verb: verb, locale: loc)
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
                            label: Text(Strings.of('repeat', loc)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _answer(state, verb, 'learned'),
                            icon: const Icon(Icons.check),
                            label: Text(Strings.of('know', loc)),
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
            Expanded(
              child: Center(child: Text(Strings.of('no_verbs_filter', loc))),
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type, String locale) {
    switch (type) {
      case 'weak':
        return Strings.of('weak_pl', locale);
      case 'strong':
        return Strings.of('strong_pl', locale);
      case 'mixed':
        return Strings.of('mixed_pl', locale);
      default:
        return Strings.of('all', locale);
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
  const _CardBack({super.key, required this.verb, required this.locale});

  final VerbModel verb;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final desc = locale == 'uk' && verb.descriptionUk.isNotEmpty
        ? verb.descriptionUk
        : verb.description;
    final hasDesc = desc.isNotEmpty;
    final theme = Theme.of(context);

    return _CardSurface(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(verb.translationFor(locale), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 18),
            Text('Präteritum: ${verb.preterite}'),
            Text('Partizip II: ${verb.pastParticiple}'),
            Text('Hilfsverb: ${verb.auxiliaryVerb}'),
            const SizedBox(height: 18),
            Text(verb.exampleSentence, textAlign: TextAlign.center),
            Text(verb.exampleTranslation, textAlign: TextAlign.center),
            if (hasDesc) ...[
              const Divider(height: 32),
              MarkdownBody(
                data: desc,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  listBullet: theme.textTheme.bodySmall,
                  code: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ],
          ),
        ),
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
