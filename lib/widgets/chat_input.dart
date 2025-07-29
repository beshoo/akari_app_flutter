import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../stores/chat_store.dart';
import '../widgets/custom_dialog.dart';
import '../utils/logger.dart';
import '../stores/auth_store.dart';
import '../utils/toast_helper.dart';

class ChatInput extends StatefulWidget {
  final VoidCallback? onMessageSent;
  final bool isEnabled;
  final String placeholder;
  final int maxLines;

  const ChatInput({
    super.key,
    this.onMessageSent,
    this.isEnabled = true,
    this.placeholder = 'اكتب رسالة...',
    this.maxLines = 4,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  int _controllerKey = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_hasText || !widget.isEnabled) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Clear immediately to prevent double submission
    _textController.clear();
    setState(() {
      _hasText = false;
    });

    try {
      final chatStore = Provider.of<ChatStore>(context, listen: false);
      await chatStore.sendMessage(text);
      widget.onMessageSent?.call();
    } catch (e) {
      Logger.log('ChatInput: Error sending message - $e');
    } finally {
      _focusNode.unfocus();
      // Force complete reset by recreating the controller
      _textController.dispose();
      _textController = TextEditingController();
      _controllerKey++;
      setState(() {});
    }
  }

  String _cleanPhoneNumber(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
  }

  Future<void> _proceedWithWhatsApp(BuildContext context) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final cleanedPhoneNumber = _cleanPhoneNumber(authStore.supportPhone);
    Logger.log('💬 Support phone from auth store:  {authStore.supportPhone}');
    Logger.log('💬 Cleaned phone number: $cleanedPhoneNumber');
    if (cleanedPhoneNumber.isNotEmpty) {
      final defaultMessage = 'أود الاستفسار عن العقار المعروض';
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$cleanedPhoneNumber&text=${Uri.encodeComponent(defaultMessage)}');
      Logger.log('💬 Final message: $defaultMessage');
      Logger.log('💬 WhatsApp URL: $whatsappUrl');
      try {
        final supported = await canLaunchUrl(whatsappUrl);
        Logger.log('💬 WhatsApp URL supported: $supported');
        if (supported) {
          final launched = await launchUrl(whatsappUrl);
          Logger.log('💬 WhatsApp launch result: $launched');
        } else {
          Logger.log('💬 WhatsApp not supported');
          if (mounted) {
            ToastHelper.showToast(context, 'تطبيق واتساب غير مثبت على هذا الجهاز', isError: true);
          }
        }
      } catch (error) {
        Logger.log('💬 Error launching WhatsApp: $error');
        if (mounted) {
          ToastHelper.showToast(context, 'حدث خطأ أثناء فتح واتساب', isError: true);
        }
      }
    } else {
      Logger.log('💬 No phone number available');
      if (mounted) {
        ToastHelper.showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider above input
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
        Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Message input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                // Delete button
                IconButton(
                  onPressed: () async {
                    bool? confirmed;
                    await showCustomDialog(
                      context: context,
                      title: 'حذف المحادثة',
                      message: 'هل أنت متأكد من حذف جميع الرسائل؟ لا يمكن التراجع عن هذا الإجراء.',
                      okButtonText: 'حذف',
                      cancelButtonText: 'إلغاء',
                      onOkPressed: () {
                        confirmed = true;
                      },
                    );

                    if (confirmed == true) {
                      try {
                        final chatStore = Provider.of<ChatStore>(context, listen: false);
                        await chatStore.deleteThread();
                      } catch (e) {
                        Logger.log('ChatInput: Error deleting thread - $e');
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
                
                // Text input field
                Expanded(
                  child: TextField(
                    key: ValueKey(_controllerKey), // Force complete rebuild when controller changes
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: widget.isEnabled,
                    maxLines: null,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                    onChanged: (value) {
                      final hasText = value.trim().isNotEmpty;
                      if (hasText != _hasText) {
                        setState(() {
                          _hasText = hasText;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontFamily: 'Cairo',
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCCCCCC),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 182, 182, 182),
                          width: 1.0,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                // Send button
                Consumer<ChatStore>(
                  builder: (context, chatStore, child) {
                    final isBotTyping = chatStore.isTyping;
                    final isSendEnabled = _hasText && widget.isEnabled && !isBotTyping;
                    return IconButton(
                      onPressed: isSendEnabled ? _sendMessage : null,
                      icon: Icon(
                        Icons.send,
                        color: isSendEnabled ? const Color(0xFFA88B67) : Colors.grey,
                        size: 24,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 2),
          
          // WhatsApp contact link
          GestureDetector(
            onTap: () => _proceedWithWhatsApp(context),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone,
                    color: Color.fromARGB(255, 88, 81, 81),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Consumer<AuthStore>(
                    builder: (context, authStore, child) {
                      return Text(
                        'الذكاء الصنعي قد يخطئ - تواصل معنا عبر الواتس أب',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 88, 81, 81),
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ],
    );
  }
}

 