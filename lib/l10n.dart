import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

enum AppLanguage { english, swahili }

class LanguageController extends ChangeNotifier {
  LanguageController._();
  static final LanguageController shared = LanguageController._();

  static const _key = 'app_language';
  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;
  bool get isSwahili => _language == AppLanguage.swahili;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final value = p.getString(_key);
    _language = value == 'sw' ? AppLanguage.swahili : AppLanguage.english;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, value == AppLanguage.swahili ? 'sw' : 'en');
  }
}

String tr(String swahili, String english) =>
    LanguageController.shared.isSwahili ? swahili : english;

Text trText(String swahili, String english, {
  bool bold = false,
  Color? color,
  double size = 13,
  TextAlign? align,
}) => Text(
      tr(swahili, english),
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: color,
      ));

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLanguage>(
      tooltip: tr('Badilisha lugha', 'Change language'),
      onSelected: LanguageController.shared.setLanguage,
      offset: const Offset(0, 46),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppLanguage.english,
          child: Row(children: [
            Icon(
              Icons.check,
              size: 18,
              color: LanguageController.shared.language == AppLanguage.english
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
            const SizedBox(width: 8),
            const Text('English'),
          ]),
        ),
        PopupMenuItem(
          value: AppLanguage.swahili,
          child: Row(children: [
            Icon(
              Icons.check,
              size: 18,
              color: LanguageController.shared.language == AppLanguage.swahili
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
            const SizedBox(width: 8),
            const Text('Swahili'),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: C.soft,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, size: 17, color: C.text),
          const SizedBox(width: 5),
          Text(
            LanguageController.shared.isSwahili ? 'SW' : 'EN',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.text),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: C.muted),
        ]),
      ),
    );
  }
}
