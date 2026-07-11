import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.status});

  final ValueNotifier<String> status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deutsche Verb',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 72, color: const Color(0xFF0F8B8D)),
              const SizedBox(height: 24),
              Text(
                'Deutsche Verb',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (context, value, _) {
                  if (value.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
