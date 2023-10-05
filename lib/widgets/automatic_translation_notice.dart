import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AutomaticTranslationNotice extends StatelessWidget {
  final bool translated;
  final EdgeInsets? padding;

  const AutomaticTranslationNotice({super.key, required this.translated, this.padding});

  @override
  Widget build(BuildContext context) {
    if (!translated) return const SizedBox.shrink();

    return Padding(
      padding: padding ?? const EdgeInsets.only(right: 10, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.of(context)!.automatischeUebersetzung,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          )
        ],
      ),
    );
  }
}
