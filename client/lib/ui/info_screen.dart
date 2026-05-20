import 'package:flutter/material.dart';

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
            onPressed: () => _openLink(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('dronov-dmitry.github.io'),
          ),
        ],
      ),
    );
  }

  void _openLink(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ссылка на сайт'),
        content: const Text('https://dronov-dmitry.github.io/'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
