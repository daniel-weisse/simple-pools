import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

extension Strings on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
}

const ink = Color(0xff18332f);
const green = Color(0xff23745d);
const paper = Color(0xfff5f6f1);

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  const Section({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String? action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action ?? c.l.confirm),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> editText(
  BuildContext context,
  String title, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(c, v.trim());
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l.cancel)),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(c, controller.text.trim());
            }
          },
          child: Text(c.l.save),
        ),
      ],
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return value;
}

class StatusPill extends StatelessWidget {
  final String text;
  final bool complete;
  const StatusPill(this.text, {super.key, this.complete = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: complete ? const Color(0xffdfeddf) : const Color(0xfff4e9cf),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}
