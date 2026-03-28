import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AvenorWebViewApp());
}

class AvenorWebViewApp extends StatelessWidget {
  const AvenorWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avenor Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C81)),
        useMaterial3: true,
      ),
      home: const WebViewShell(),
    );
  }
}

class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  static const productionUrl = String.fromEnvironment(
    'AVENOR_WEB_URL',
    defaultValue: 'https://avenor.floodmonitoringsystem.my.id/',
  );

  late final WebViewController controller;
  int progress = 0;
  bool hasError = false;
  String? lastError;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) => setState(() => progress = value),
          onPageStarted: (_) => setState(() {
            hasError = false;
            lastError = null;
          }),
          onWebResourceError: (error) => setState(() {
            hasError = true;
            lastError = error.description;
          }),
        ),
      )
      ..loadRequest(Uri.parse(productionUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avenor Web'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.reload,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Column(
        children: [
          if (progress < 100 && !hasError)
            LinearProgressIndicator(value: progress / 100),
          Expanded(
            child: hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 56),
                          const SizedBox(height: 12),
                          const Text(
                            'Aplikasi tidak bisa memuat halaman.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lastError ?? 'Unknown error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: controller.reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}
