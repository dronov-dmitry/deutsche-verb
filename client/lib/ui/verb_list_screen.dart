import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/verb_model.dart';
import '../providers/app_state.dart';
import '../strings.dart';

class VerbListScreen extends StatelessWidget {
  const VerbListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.locale;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.of('verbs', loc))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: state.setSearchQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: Strings.of('search', loc),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['All', 'A1', 'A2', 'B1', 'B2', 'C1'].map((level) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level == 'All' ? Strings.of('all', loc) : level),
                    selected: state.levelFilter == level,
                    onSelected: (_) => state.setLevelFilter(level),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ...['All', 'weak', 'strong', 'mixed'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type, loc)),
                      selected: state.typeFilter == type,
                      onSelected: (_) => state.setTypeFilter(type),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.visibleVerbs.length,
              itemBuilder: (context, index) {
                final verb = state.visibleVerbs[index];
                return ListTile(
                  title: Text(verb.infinitive),
                  subtitle: Text('${verb.translationFor(loc)} · ${verb.level} · ${_typeLabel(verb.type, loc)}'),
                  trailing: verb.progressStatus == 'learned'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => _showVerbDetails(context, verb, loc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type, String locale) {
    switch (type) {
      case 'weak':
        return Strings.of('weak', locale);
      case 'strong':
        return Strings.of('strong', locale);
      case 'mixed':
        return Strings.of('mixed', locale);
      default:
        return Strings.of('all', locale);
    }
  }

  void _showVerbDetails(BuildContext context, VerbModel verb, String locale) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(verb.infinitive, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(verb.translationFor(locale)),
              const SizedBox(height: 4),
              Text('${verb.level} · ${_typeLabel(verb.type, locale)}'),
              const Divider(height: 28),
              Text('Präteritum: ${verb.preterite}'),
              Text('Partizip II: ${verb.pastParticiple}'),
              Text('Hilfsverb: ${verb.auxiliaryVerb}'),
              const SizedBox(height: 16),
              Text(verb.exampleSentence, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(verb.exampleTranslation),
            ],
          ),
        );
      },
    );
  }
}
