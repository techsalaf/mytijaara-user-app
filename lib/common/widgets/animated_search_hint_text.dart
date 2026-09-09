import 'package:flutter/material.dart';
import 'package:sixam_mart/util/styles.dart';

class AnimatedSearchHintText extends StatefulWidget {
  final String prefixText;
  final List<String> animatedWords;
  final TextStyle? style;

  const AnimatedSearchHintText({super.key, required this.prefixText, required this.animatedWords, this.style});

  @override
  State<AnimatedSearchHintText> createState() => _AnimatedSearchHintTextState();
}

class _AnimatedSearchHintTextState extends State<AnimatedSearchHintText> {
  static const List<String> _fallbackAnimatedWords = <String>['Bread', 'Napa', 'Sunglasses'];
  static const Duration _typingSpeed = Duration(milliseconds: 130);
  static const Duration _erasingSpeed = Duration(milliseconds: 70);
  static const Duration _pauseAfterWord = Duration(milliseconds: 1400);
  static const Duration _pauseBeforeNext = Duration(milliseconds: 400);

  late final List<String> _animatedWords;
  int _wordIndex = 0;
  String _animatedText = '';

  @override
  void initState() {
    super.initState();
    _animatedWords = widget.animatedWords.isNotEmpty ? widget.animatedWords : _fallbackAnimatedWords;
    _startTyping();
  }

  Future<void> _startTyping() async {
    while (mounted) {
      final String currentWord = _animatedWords[_wordIndex];

      for (int i = 1; i <= currentWord.length; i++) {
        await Future<void>.delayed(_typingSpeed);
        if (!mounted) return;
        setState(() => _animatedText = currentWord.substring(0, i));
      }

      await Future<void>.delayed(_pauseAfterWord);
      if (!mounted) return;

      for (int i = _animatedText.length - 1; i >= 0; i--) {
        await Future<void>.delayed(_erasingSpeed);
        if (!mounted) return;
        setState(() => _animatedText = currentWord.substring(0, i));
      }

      await Future<void>.delayed(_pauseBeforeNext);
      if (!mounted) return;

      _wordIndex = (_wordIndex + 1) % _animatedWords.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.prefixText,
            style: widget.style ?? robotoRegular,
          ),
          if (_animatedText.isNotEmpty)
            TextSpan(
              text: ' $_animatedText',
              style:  robotoMedium.copyWith(color: Theme.of(context).hintColor),
            ),
        ],
      ),
    );
  }
}
