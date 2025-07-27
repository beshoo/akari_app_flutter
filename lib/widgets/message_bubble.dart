import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/chat_message_model.dart';
import '../providers/chat_provider.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final VoidCallback? onLinkTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == SenderType.user;
    
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 100 : 0,    // User messages align left (small left margin)
        right: isUser ? 0 : 100,   // AI messages align right (small right margin)
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser 
            ? CrossAxisAlignment.start    // User messages align left
            : CrossAxisAlignment.end,     // AI messages align right
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser 
                  ? const Color.fromARGB(208, 144, 104, 4)     // Gold/brown for user messages 
                  : const Color.fromARGB(255, 215, 215, 215),    // Light gray for AI messages
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomRight: isUser 
                    ? const Radius.circular(4)     // Sharp corner for user (left side)
                    : const Radius.circular(18),
                bottomLeft: isUser 
                    ? const Radius.circular(18)
                    : const Radius.circular(4),    // Sharp corner for AI (right side)
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content with parsed parts
                _buildMessageContent(context, isUser),
                
                // Timestamp and status
                if (showTimestamp) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTimestampAndStatus(isUser),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    // If only one part and it's regular text, render directly
    if (message.parsedParts.length == 1 && 
        !message.parsedParts.first.isLink && 
        !message.parsedParts.first.isBold) {
      return _buildRegularText(message.parsedParts.first, isUser);
    }
    
    return Wrap(
      children: message.parsedParts.map((part) {
        if (part.isLink) {
          return _buildLinkText(context, part, isUser);
        } else if (part.isBold) {
          return _buildBoldText(part, isUser);
        } else {
          return _buildRegularText(part, isUser);
        }
      }).toList(),
    );
  }

  Widget _buildRegularText(MessagePart part, bool isUser) {
    return Text(
      part.text,
      style: TextStyle(
        fontSize: 16,
        color: isUser ? Colors.white : const Color(0xFF000000),
        fontFamily: 'Cairo',
        height: 1.4,
      ),
    );
  }

  Widget _buildBoldText(MessagePart part, bool isUser) {
    return Text(
      part.text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isUser ? Colors.white : const Color(0xFF000000),
        fontFamily: 'Cairo',
        height: 1.4,
      ),
    );
  }

  Widget _buildLinkText(BuildContext context, MessagePart part, bool isUser) {
    return GestureDetector(
      onTap: () {
        if (part.linkType != null && part.referenceId != null) {
          ChatProvider.of(context, listen: false).handleLinkTap(
            part.linkType!,
            part.referenceId!,
            context,
          );
        }
        onLinkTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isUser 
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFA88B67).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser 
                ? Colors.white.withValues(alpha: 0.5)
                : const Color(0xFFA88B67).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          part.text,
          style: TextStyle(
            fontSize: 12,
           
            color: isUser ? Colors.white : const Color(0xFF007BFF),
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTimestampAndStatus(bool isUser) {
    final timeFormatter = DateFormat('hh:mm a', 'ar');
    final timeString = timeFormatter.format(DateTime.now());
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Timestamp
        Text(
          timeString,
          style: TextStyle(
            fontSize: 12,
            color: isUser 
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF999999),
            fontFamily: 'Cairo',
          ),
        ),
        
        // Status indicators for user messages
        if (isUser) ...[
          const SizedBox(width: 4),
          _buildStatusIndicator(),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: Colors.white.withValues(alpha: 0.8),
        );
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 16,
          color: const Color(0xFF93c5fd), // Blue for delivered/read
        );
    }
  }
}

// Helper widget for message list with automatic scrolling
class MessagesList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final Widget? typingIndicator;
  final EdgeInsetsGeometry padding;
  final ScrollController? scrollController;

  const MessagesList({
    super.key,
    required this.messages,
    this.isTyping = false,
    this.typingIndicator,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.scrollController,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-scroll when messages change or typing status changes
    if (oldWidget.messages.length != widget.messages.length ||
        oldWidget.isTyping != widget.isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.messages.length + (widget.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.messages.length) {
          return MessageBubble(
            message: widget.messages[index],
            showTimestamp: _shouldShowTimestamp(index),
          );
        } else {
          // Typing indicator
          return widget.typingIndicator ?? const SizedBox.shrink();
        }
      },
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == widget.messages.length - 1) return true;
    
    final currentMessage = widget.messages[index];
    final nextMessage = widget.messages[index + 1];
    
    // Show timestamp if next message is from different sender
    // or if there's more than 5 minutes between messages
    final timeDifference = nextMessage.timestamp.difference(currentMessage.timestamp);
    
    return currentMessage.senderType != nextMessage.senderType ||
           timeDifference.inMinutes > 5;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
} 