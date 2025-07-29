/// Model representing content shared from messaging apps
class SharedContent {
  final String text;
  final String? appName;
  final String? senderInfo;
  final DateTime receivedAt;
  final String? conversationContext;
  
  const SharedContent({
    required this.text,
    this.appName,
    this.senderInfo,
    required this.receivedAt,
    this.conversationContext,
  });
  
  factory SharedContent.fromIntent({
    required String text,
    String? appName,
    String? senderInfo,
    String? conversationContext,
  }) {
    return SharedContent(
      text: text,
      appName: appName,
      senderInfo: senderInfo,
      receivedAt: DateTime.now(),
      conversationContext: conversationContext,
    );
  }
  
  @override
  String toString() {
    return 'SharedContent{text: $text, appName: $appName, receivedAt: $receivedAt}';
  }
}