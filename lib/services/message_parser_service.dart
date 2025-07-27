import '../data/models/chat_message_model.dart';

class MessageParserService {
  // Critical Regex Patterns from requirements
  static final RegExp apartmentPattern = RegExp(r'\[(Apartment|شقة)\s*\|\s*الرقم المرجعي:\s*(\d+)\]');
  static final RegExp sharePattern = RegExp(r'\[(Share|سهم)\s*\|\s*الرقم المرجعي:\s*(\d+)\]');
  static final RegExp boldTextPattern = RegExp(r'\*\*(.*?)\*\*');
  static final RegExp documentReferencePattern = RegExp(r'【\d+:\d+†[^】]+】');
  static final RegExp nullPattern = RegExp(r'\bnull\b');
  static final RegExp hashPattern = RegExp(r'##');

  static List<MessagePart> parseMessage(String text) {
    // For simple text without special patterns, return single part
    if (!text.contains('[') && !text.contains('**') && !documentReferencePattern.hasMatch(text)) {
      return [MessagePart(text: text.trim())];
    }
    
    // Step 1: Clean text by removing unwanted patterns first
    String cleanedText = _cleanText(text);
    
    // Step 2: Find all reference matches and sort by position
    List<_ReferenceMatch> referenceMatches = _findReferenceMatches(cleanedText);
    
    // Step 3: Add instruction text with RTL arrow when references found
    if (referenceMatches.isNotEmpty) {
      cleanedText = _addInstructionText(cleanedText);
      // Re-find matches after adding instruction text
      referenceMatches = _findReferenceMatches(cleanedText);
    }
    
    // Step 4: Build message parts array with text and clickable links
    return _buildMessageParts(cleanedText, referenceMatches);
  }

  static String _cleanText(String text) {
    String cleaned = text;
    
    // Remove document references
    cleaned = cleaned.replaceAll(documentReferencePattern, '');
    
    // Remove null patterns
    cleaned = cleaned.replaceAll(nullPattern, '');
    
    // Remove hash patterns
    cleaned = cleaned.replaceAll(hashPattern, '');
    
    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  static List<_ReferenceMatch> _findReferenceMatches(String text) {
    List<_ReferenceMatch> matches = [];
    
    // Find apartment matches
    for (RegExpMatch match in apartmentPattern.allMatches(text)) {
      matches.add(_ReferenceMatch(
        start: match.start,
        end: match.end,
        fullMatch: match.group(0)!,
        type: 'apartment',
        referenceId: match.group(2)!,
      ));
    }
    
    // Find share matches
    for (RegExpMatch match in sharePattern.allMatches(text)) {
      matches.add(_ReferenceMatch(
        start: match.start,
        end: match.end,
        fullMatch: match.group(0)!,
        type: 'share',
        referenceId: match.group(2)!,
      ));
    }
    
    // Sort matches by position
    matches.sort((a, b) => a.start.compareTo(b.start));
    
    return matches;
  }

  static String _addInstructionText(String text) {
    // Add RTL instruction text at the beginning
   // const String instruction = "انقر على الروابط الزرقاء ⬅️ أدناه للعرض\n\n";
    return  text;
  }

  static List<MessagePart> _buildMessageParts(String text, List<_ReferenceMatch> referenceMatches) {
    List<MessagePart> parts = [];
    int currentIndex = 0;
    
    for (_ReferenceMatch match in referenceMatches) {
      // Add text before the reference (if any)
      if (currentIndex < match.start) {
        String beforeText = text.substring(currentIndex, match.start);
        parts.addAll(_parseBoldText(beforeText));
      }
      
      // Add the clickable reference link
      String linkText = 'إذهب إلى الإعلان رقم #${match.referenceId} ⬅️';
      
      parts.add(MessagePart(
        text: linkText,
        isLink: true,
        linkType: match.type,
        referenceId: match.referenceId,
      ));
      
      currentIndex = match.end;
    }
    
    // Add remaining text after the last reference
    if (currentIndex < text.length) {
      String remainingText = text.substring(currentIndex);
      parts.addAll(_parseBoldText(remainingText));
    }
    
    // If no references found, just parse the text for bold formatting
    if (referenceMatches.isEmpty && parts.isEmpty) {
      parts.addAll(_parseBoldText(text));
    }
    
    return parts;
  }

  static List<MessagePart> _parseBoldText(String text) {
    List<MessagePart> parts = [];
    int currentIndex = 0;
    
    for (RegExpMatch match in boldTextPattern.allMatches(text)) {
      // Add text before the bold text (if any)
      if (currentIndex < match.start) {
        String beforeText = text.substring(currentIndex, match.start);
        if (beforeText.isNotEmpty) {
          parts.add(MessagePart(text: beforeText));
        }
      }
      
      // Add the bold text
      String boldText = match.group(1)!;
      if (boldText.isNotEmpty) {
        parts.add(MessagePart(text: boldText, isBold: true));
      }
      
      currentIndex = match.end;
    }
    
    // Add remaining text after the last bold text
    if (currentIndex < text.length) {
      String remainingText = text.substring(currentIndex);
      if (remainingText.isNotEmpty) {
        parts.add(MessagePart(text: remainingText));
      }
    }
    
    // If no bold text found, return the original text as a single part
    if (parts.isEmpty && text.isNotEmpty) {
      parts.add(MessagePart(text: text));
    }
    
    return parts;
  }
}

class _ReferenceMatch {
  final int start;
  final int end;
  final String fullMatch;
  final String type;
  final String referenceId;

  _ReferenceMatch({
    required this.start,
    required this.end,
    required this.fullMatch,
    required this.type,
    required this.referenceId,
  });
} 