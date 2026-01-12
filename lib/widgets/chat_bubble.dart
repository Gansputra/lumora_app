import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isBot;

  const ChatBubble({super.key, required this.message, required this.isBot});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : const Color(0xFF1E3C72),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 0 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isBot
            ? MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              )
            : Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
      ),
    );
  }
}
