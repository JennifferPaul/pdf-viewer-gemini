// text_highlighting.dart

import 'package:flutter/material.dart';

class TextHighlighting {
  Set<String> highlightedTexts = {}; // Use Set for unique values

  bool isHighlighted(String text) {
    return highlightedTexts.contains(text);
  }

  void toggleHighlight(String text) {
    if (highlightedTexts.contains(text)) {
      highlightedTexts.remove(text); // Remove if already highlighted
    } else {
      highlightedTexts.add(text); // Add to highlight
    }
  }

  Widget buildHighlightedText(String text) {
    bool isHighlighted = highlightedTexts.contains(text);
    return Text(
      text,
      style: TextStyle(
        color: isHighlighted ? Colors.yellow : Colors.black,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
