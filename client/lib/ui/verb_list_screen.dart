import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: hasDesc ? 0.75 : 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(verb.infinitive, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    SelectableText(verb.translationFor(locale)),
                    const SizedBox(height: 4),
                    SelectableText('${verb.level} · ${_typeLabel(verb.type, locale)}'),
                    const Divider(height: 28),
                    SelectableText('Präteritum: ${verb.preterite}'),
                    SelectableText('Partizip II: ${verb.pastParticiple}'),
                    SelectableText('Hilfsverb: ${verb.auxiliaryVerb}'),
                    const SizedBox(height: 16),
                    SelectableText(verb.exampleSentence, style: const TextStyle(fontWeight: FontWeight.w600)),
                    SelectableText(verb.exampleTranslationFor(locale)),
                    if (hasDesc) ...[
                       const Divider(height: 28),
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
                         ),
                       ),
                     ],
                    if (hasVfDesc) ...[
                      const Divider(height: 28),
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
                        ),
                      ),
                    ],
                    // ССЫЛКА НА САЙТ https://www.verbformen.com/
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
            );
          },
        );
      },
    );
  }
}
