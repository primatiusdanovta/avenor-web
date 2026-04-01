import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String kDefaultWebUrl = String.fromEnvironment(
  'AVENOR_WEB_URL',
  defaultValue: 'https://avenorperfume.site/administrator',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AvenorWebViewApp());
}

class AvenorWebViewApp extends StatelessWidget {
  const AvenorWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewShell(),
    );
  }
}

class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  InAppWebViewController? controller;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avenor Web'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (progress < 1.0) LinearProgressIndicator(value: progress),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(kDefaultWebUrl),
              ),
              onWebViewCreated: (webController) {
                controller = webController;
              },
              onProgressChanged: (webController, value) {
                setState(() {
                  progress = value / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
