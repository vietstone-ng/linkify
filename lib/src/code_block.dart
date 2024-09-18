import 'package:linkify/linkify.dart';

final _codeBlockRegex =
    RegExp(r'^([\s\S]*?)((\n|^)+```(.*)\n([\s\S]*?)\n```(\n|$)|`([^`\n]*)`)');

// group(1) = ([\s\S]*?) : anything before code block
// group(2) = ((\n|^)```(.*)\n([\s\S]*?)\n```(\n|$)|`([^`\n]*)`) : code block, triple backticks or single backticks
// group(3) = (\n|^) : before triple backticks, must be new line or start of string
// group(4) = (.*) : language (dart, python, etc) inside triple backticks
// group(5) = ([\s\S]*?) : code block inside triple backticks
// group(6) = (\n|$) : new line or end of string after triple backticks
// group(7) = ([^`\n]*) : inline-code inside single backticks

class CodeBlockLinkifier extends Linkifier {
  final bool printDebug;

  const CodeBlockLinkifier({this.printDebug = false});

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    for (var element in elements) {
      if (element is TextElement) {
        var match = _codeBlockRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          final text = element.text.replaceFirst(match.group(0)!, '');

          if (printDebug) {
            print({
              'group_1': match.group(1),
              'group_2': match.group(2),
              'group_3': match.group(3),
              'group_4': match.group(4),
              'group_5': match.group(5),
              'group_6': match.group(6),
              'group_7': match.group(7),
            });

            print('after text: $text');
          }

          final group_1 = match.group(1) ?? '';
          final group_3 = match.group(3) ?? '';
          final beforeCode = group_1 + group_3;

          if (beforeCode.isNotEmpty) {
            list.add(TextElement(beforeCode));
          }

          if (match.group(2)?.isNotEmpty == true) {
            if (match.group(5) != null) {
              list.add(CodeBlockElement(
                match.group(5)!,
                language: match.group(4),
                isTripleBackticks: true,
              ));
            }

            if (match.group(7) != null) {
              list.add(CodeBlockElement(
                match.group(7)!,
                isTripleBackticks: false,
              ));
            }
          }

          if (text.isNotEmpty) {
            list.addAll(parse([TextElement(text)], options));
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

class CodeBlockElement extends LinkifyElement {
  final String? language;
  final String code;
  final bool isTripleBackticks;

  CodeBlockElement(this.code, {this.language, this.isTripleBackticks = false})
      : super(code) {
    Future.microtask(() => toString());
  }

  @override
  String toString() {
    return 'CodeBlockElement: ${language ?? ''} \n$code\n';
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(language, code);

  @override
  bool equals(other) =>
      other is CodeBlockElement &&
      other.language == language &&
      other.code == code;
}
