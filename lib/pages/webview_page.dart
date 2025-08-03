import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_spinner.dart';
import '../stores/auth_store.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? title;
  
  const WebViewPage({
    super.key,
    required this.url,
    this.title,
  });

  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        _controller?.reload();
      },
    );
    _initializeWebView();
  }

  void _initializeWebView() {
    // The original _initializeWebView function is removed as per the new_code.
    // The new_code provides the onLoadStop callback which handles the webview initialization.
  }

  void _scrollToTop() async {
    await _controller?.evaluateJavascript(source: 'window.scrollTo({top: 0, behavior: "smooth"});');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        final isAuthenticated = authStore.isAuthenticated;
        
        return Scaffold(
          appBar: CustomAppBar(
            showBackButton: true,
            showLogo: true,
            onBackPressed: () => Navigator.pop(context),
            showAddAdButton: false, // Only show if authenticated
            title: null,

        showFavoritesButton: isAuthenticated,
        showHelpButton: isAuthenticated,
        showSearchButton: isAuthenticated,
        showNotificationButton: isAuthenticated,
            // onNotificationPressed removed to use default
          ),
          body: Stack(
            children: [
              if (_hasError)
                _buildErrorView()
              else
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: InAppWebViewSettings(
                    underPageBackgroundColor: Color(0xFFF7F5F2), // Your desired color
                    transparentBackground: true,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false, // optional
                  ),
                  pullToRefreshController: _pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      _isLoading = false;
                    });
                    _pullToRefreshController?.endRefreshing();
                  },
                  onReceivedError: (controller, request, error) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = error.description;
                    });
                    _pullToRefreshController?.endRefreshing();
                  },
                  onScrollChanged: (controller, x, y) {
                    setState(() {
                      _showScrollToTop = y > 0;
                    });
                  },
                ),
              if (_isLoading)
                _buildLoadingView(),
              if (_showScrollToTop && !_isLoading && !_hasError)
                Positioned(
                  left: 16,
                  bottom: 32 + MediaQuery.of(context).viewPadding.bottom,
                  child: SafeArea(
                    child: FloatingActionButton(
                      onPressed: _scrollToTop,
                      backgroundColor: Color(0xFF633e3d),
                      heroTag: 'scrollToTop',
                      child: Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Color(0xFFF7F5F2),
      child: Align(
        alignment: Alignment(0.0, -0.2),
        child: CustomSpinner(size: 50.0),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'خطأ في تحميل الصفحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'تعذر تحميل المحتوى',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Cairo',
                color: Color(0xFF6b7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF633e3d),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _controller?.reload();
  }
} 