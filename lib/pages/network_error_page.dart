import 'package:akari_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class NetworkErrorPage extends StatefulWidget {
  final Future<void> Function() onRetry;

  const NetworkErrorPage({super.key, required this.onRetry});

  @override
  State<NetworkErrorPage> createState() => _NetworkErrorPageState();
}

class _NetworkErrorPageState extends State<NetworkErrorPage> {
  bool _isLoading = false;

  Future<void> _handleRetry() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onRetry();
      // If we reach here without exception, the retry was successful
      // The page should be popped by the calling code
    } catch (e) {
      // If retry fails, show a brief message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في إعادة المحاولة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/connection_lost.png',
                  width: 250,
                  height: 250,
                ),
                const SizedBox(height: 24),
                const Text(
                  'خطأ في الاتصال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: CustomButton(
                    title: 'إعادة المحاولة',
                    onPressed: _handleRetry,
                    isLoading: _isLoading,
                    hasGradient: true,
                    height: 50,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 