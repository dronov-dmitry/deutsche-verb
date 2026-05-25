import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _progressFilter = 'all';
  List<VerbModel> _shuffledVerbs = [];

  List<VerbModel> _filtered(List<VerbModel> verbs) {
    return verbs.where((v) {
      final matchLevel = _levelFilters.isEmpty || _levelFilters.contains(v.level);
      final matchType = _typeFilters.isEmpty || _typeFilters.any((f) => _mapTypeFilter(f) == v.type);
      final matchProgress = _progressFilter == 'all' ||
          (_progressFilter == 'learned' && v.progressStatus == 'learned') ||
          (_progressFilter == 'learning' && v.progressStatus != 'learned') ||
          (_progressFilter == 'repeat' && v.markedForRepeat);
      return matchLevel && matchType && matchProgress;
    }).toList();
  }

  void _reshuffle(List<VerbModel> verbs) {
    _shuffledVerbs = List.from(verbs)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.locale;
    final verbs = _filtered(state.verbs);

    if (verbs.isEmpty) {
      _shuffledVerbs = [];
    } else if (_shuffledVerbs.length != verbs.length ||
        !_shuffledVerbs.every((v) => verbs.contains(v)) ||
        _index >= _shuffledVerbs.length) {
      _reshuffle(verbs);
      _index = 0;
      _flipped = false;
    }

    final hasVerbs = _shuffledVerbs.isNotEmpty;
    final verb = hasVerbs ? _shuffledVerbs[_index] : null;

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
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ...['all', 'learned', 'learning', 'repeat'].map((progress) {
                  final selected = _progressFilter == progress;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(Strings.of('progress_$progress', loc), style: const TextStyle(fontSize: 13)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _progressFilter = progress;
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
                            onPressed: () => _answer(state, verb, 'learning', markedForRepeat: true),
                            icon: const Icon(Icons.replay),
                            label: Text(Strings.of('repeat', loc)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _answer(state, verb, 'learned', markedForRepeat: false),
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
      case 'regular':
        return Strings.of('weak_pl', locale);
      case 'strong':
      case 'irregular':
        return Strings.of('strong_pl', locale);
      case 'mixed':
        return Strings.of('mixed_pl', locale);
      default:
        return Strings.of('all', locale);
    }
  }

  String _mapTypeFilter(String filter) {
    switch (filter) {
      case 'weak':
        return 'regular';
      case 'strong':
        return 'irregular';
      default:
        return filter;
    }
  }

  void _answer(AppState state, VerbModel verb, String status, {bool? markedForRepeat}) {
    state.markVerb(verb, status, markedForRepeat: markedForRepeat);
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
    String cleanDesc = desc;
    if (hasDesc) {
      cleanDesc = desc.replaceAll(RegExp(r'### Пример\n.*', dotAll: true), '');
      cleanDesc = cleanDesc.replaceAll(RegExp(r'### Приклад\n.*', dotAll: true), '');
    }
    final vfDesc = verb.descriptionVerbformenFor(locale);
    final hasVfDesc = vfDesc.isNotEmpty;
    final theme = Theme.of(context);
    // final vfUrl = verb.verbformenUrlFor(locale);

    return _CardSurface(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(verb.translationFor(locale), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 18),
            SelectableText('Präteritum: ${verb.preterite}'),
            SelectableText('Partizip II: ${verb.pastParticiple}'),
            SelectableText('Hilfsverb: ${verb.auxiliaryVerb}'),
            const SizedBox(height: 18),
            SelectableText(verb.exampleSentence, textAlign: TextAlign.center),
            SelectableText(verb.exampleTranslationFor(locale), textAlign: TextAlign.center),
            if (hasDesc) ...[
              const Divider(height: 32),
              MarkdownBody(
                data: cleanDesc,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  listBullet: theme.textTheme.bodySmall,
                  code: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
            if (hasVfDesc) ...[
              const Divider(height: 32),
              MarkdownBody(
                data: vfDesc,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  tableBorder: TableBorder.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                  tableHead: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  tableBody: theme.textTheme.bodySmall,
                  listBullet: theme.textTheme.bodySmall,
                  code: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
            // ССЫЛКА НА https://www.verbformen.com/
            // if (vfUrl.isNotEmpty) ...[
            //   const SizedBox(height: 20),
            //   InkWell(
            //     onTap: () async {
            //       final uri = Uri.parse(vfUrl);
            //       if (await canLaunchUrl(uri)) {
            //         await launchUrl(uri, mode: LaunchMode.externalApplication);
            //       }
            //     },
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Icon(Icons.open_in_new, size: 14, color: theme.colorScheme.primary),
            //         const SizedBox(width: 6),
            //         Text(
            //           'verbformen.com',
            //           style: theme.textTheme.bodySmall?.copyWith(
            //             color: theme.colorScheme.primary,
            //             decoration: TextDecoration.underline,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],
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
