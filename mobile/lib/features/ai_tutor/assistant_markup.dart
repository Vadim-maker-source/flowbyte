class AssistantContentSegment {
  const AssistantContentSegment.text(this.content)
    : isCode = false,
      language = null;

  const AssistantContentSegment.code(this.content, {this.language = 'python'})
    : isCode = true;

  final String content;
  final bool isCode;
  final String? language;
}

List<AssistantContentSegment> parseAssistantContent(String source) {
  final segments = <AssistantContentSegment>[];
  final fenced = RegExp(
    r'```(?:python|py)?[ \t]*\r?\n([\s\S]*?)```',
    caseSensitive: false,
  );
  var cursor = 0;
  var foundClosedFence = false;
  for (final match in fenced.allMatches(source)) {
    foundClosedFence = true;
    _addText(segments, source.substring(cursor, match.start));
    final code = _trimCode(match.group(1) ?? '');
    if (code.isNotEmpty) {
      segments.add(AssistantContentSegment.code(code));
    }
    cursor = match.end;
  }
  if (!foundClosedFence && source.trim().isNotEmpty) {
    final openFence = RegExp(
      r'```(?:python|py)?[ \t]*\r?\n',
      caseSensitive: false,
    ).firstMatch(source);
    if (openFence != null) {
      _addText(segments, source.substring(0, openFence.start));
      final code = _trimCode(
        source.substring(openFence.end).replaceFirst(RegExp(r'`{2,3}\s*$'), ''),
      );
      if (code.isNotEmpty) segments.add(AssistantContentSegment.code(code));
    } else {
      segments.add(AssistantContentSegment.text(source.trim()));
    }
    return segments;
  }
  _addText(segments, source.substring(cursor));
  return segments;
}

void _addText(List<AssistantContentSegment> segments, String value) {
  final text = value.trim();
  if (text.isNotEmpty) segments.add(AssistantContentSegment.text(text));
}

String _trimCode(String value) => value
    .replaceFirst(RegExp(r'^[\r\n]+'), '')
    .replaceFirst(RegExp(r'[\r\n]+$'), '');
