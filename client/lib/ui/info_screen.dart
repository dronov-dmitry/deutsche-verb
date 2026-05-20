import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Информация')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.info_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            'Deutsche Verb',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Приложение для изучения немецких глаголов с карточками и прогрессом.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Автор',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Дронов Дмитрий'),
          const SizedBox(height: 16),
          const Text(
            'Разработчик и энтузиаст немецкого языка. Если у вас есть вопросы или предложения, посетите сайт автора.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openUrl(context, 'https://dronov-dmitry.github.io/'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Сайт автора'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(context, 'https://github.com/dronov-dmitry/'),
            icon: const Icon(Icons.code),
            label: const Text('GitHub профиль'),
          ),
        ],
      ),
    );
  }

  void _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть: $url')),
        );
      }
    }
  }
}
