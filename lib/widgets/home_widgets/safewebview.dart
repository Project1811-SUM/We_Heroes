import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebView extends StatefulWidget {
  final String url;

  const SafeWebView({Key? key, required this.url}) : super(key: key);

  @override
  _SafeWebViewState createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController and load the URL
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource loading errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to load page")),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safe Web View"),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller), // Display the WebView
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ), // Show loading spinner while page loads
        ],
      ),
    );
  }
}
