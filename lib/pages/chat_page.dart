import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/chat_store.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_dialog.dart';
import '../utils/logger.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    
    // Initialize and refresh chat store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatStore = Provider.of<ChatStore>(context, listen: false);
      chatStore.refreshState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Logger.log('ChatPage: App resumed');
    }
  }

  void _onScroll() {
    final showButton = _scrollController.hasClients &&
        _scrollController.offset > 200;
    
    if (showButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<bool> _onWillPop() async {
    bool? shouldExit;
    await showCustomDialog(
      context: context,
      title: 'إغلاق التطبيق',
      message: 'هل تريد إغلاق التطبيق؟',
      okButtonText: 'إغلاق',
      cancelButtonText: 'البقاء',
      onOkPressed: () {
        shouldExit = true;
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _onWillPop();
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: const CustomAppBar(
          showBackButton: true,
          showNotificationButton: true,
          showSearchButton: true,
          showFavoritesButton: true,
          showHelpButton: true,
        ),
        body: Consumer<ChatStore>(
          builder: (context, chatStore, child) {
            // Auto-scroll to bottom when messages or typing state changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
            
            // Show loading while store is initializing
            if (!chatStore.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            return Column(
              children: [
                // Messages area
                Expanded(
                  child: Stack(
                    children: [
                      // Background gradient (optional)
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F5F2),
                        ),
                      ),
                      // Messages list
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: MediaQuery.of(context).viewPadding.bottom + 8,
                        ),
                        itemCount: chatStore.messages.length +
                            (chatStore.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < chatStore.messages.length) {
                            return MessageBubble(
                              message: chatStore.messages[index],
                              showTimestamp: _shouldShowTimestamp(
                                index,
                                chatStore.messages,
                              ),
                            );
                          } else {
                            // Typing indicator
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: TypingIndicator(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Chat input with safe area
                SafeArea(
                  child: const ChatInput(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(int index, List messages) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    // Show timestamp if next message is from different sender
    // or if there's more than 5 minutes between messages
    final timeDifference = nextMessage.timestamp.difference(currentMessage.timestamp);
    
    return currentMessage.senderType != nextMessage.senderType ||
           timeDifference.inMinutes > 5;
  }
}

// Note: ChatStore is now provided globally in main.dart
// No wrapper needed - use ChatPage directly

 