import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ai_panel.dart';
import '../widgets/common.dart';
import '../l10n.dart';
import 'dashboard_page.dart';
import 'entry_page.dart';
import 'jumuiya_page.dart';
import 'ledger_page.dart';
import 'members_page.dart';
import 'security_page.dart';

class Shell extends StatefulWidget {
  final AppState app;
  final PinService pin;
  final VoidCallback onLock;
  const Shell({super.key, required this.app, required this.pin, required this.onLock});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 1;

  List<(IconData, String, String)> _items() => [
        (Icons.dashboard_outlined, 'Dashboard', 'Dashboard'),
        (Icons.edit_outlined, 'Data Entry', 'Uingizaji wa Data'),
        (Icons.groups_outlined, 'Jumuiya', 'Jumuiya'),
        (Icons.contacts_outlined, 'Contributors', 'Majina ya Watoa Michango'),
        (Icons.menu_book_outlined, 'Records Ledger', 'Daftari la Rekodi'),
        (Icons.lock_outline, 'Security PIN', 'Usalama wa PIN'),
      ];

  Widget _page() => ColoredBox(
        color: C.bg,
        child: SizedBox.expand(
          child: KeyedSubtree(
            key: ValueKey(_i),
            child: switch (_i) {
              0 => DashboardPage(app: widget.app),
              1 => EntryPage(app: widget.app),
              2 => JumuiyaPage(app: widget.app),
              3 => MembersPage(app: widget.app),
              4 => LedgerPage(app: widget.app),
              _ => SecurityPage(pin: widget.pin, onLock: widget.onLock),
            },
          ),
        ),
      );

  Widget _topBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(
          color: C.bgDeep,
          border: Border(bottom: BorderSide(color: C.border, width: .8)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset('assets/logo.png', width: 38, height: 38),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tl(context, 'WANAWAKE WAKATOLIKI TANZANIA', 'CATHOLIC WOMEN OF TANZANIA', bold: true, size: 12),
              t('WA-WA-TA', color: C.navy, size: 11),
            ]),
          ),
          const LanguageSwitcher(),
        ]),
      );

  Widget _sidebar() {
    final items = _items();
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: C.bgDeep,
        border: Border(right: BorderSide(color: C.border, width: .8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        for (var i = 0; i < items.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _i = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _i == i ? C.cViolet : Colors.transparent,
                border: _i == i ? null : Border.all(color: C.border.withOpacity(.55), width: .8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(items[i].$1, size: 19,
                    color: _i == i ? Colors.white : C.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(items[i].$3, items[i].$2),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: _i == i ? FontWeight.w600 : FontWeight.w400,
                        color: _i == i ? Colors.white : C.muted),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _footer() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text('POWERED BY E-LAPS',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 2.4, color: C.muted.withOpacity(.6))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.app, LanguageController.shared]),
      builder: (context, _) => LayoutBuilder(builder: (context, cons) {
        final wide = cons.maxWidth >= 950;
        if (wide) {
          return Scaffold(
            backgroundColor: C.bg,
            body: Column(children: [
              _topBar(),
              Expanded(
                child: Row(children: [
                  _sidebar(),
                  Expanded(child: _page()),
                  SizedBox(width: 270, child: AiPanel(app: widget.app)),
                ]),
              ),
              _footer(),
            ]),
          );
        }
        final items = _items();
        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              _topBar(),
              Expanded(child: _page()),
            ]),
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: C.rose,
            foregroundColor: Colors.white,
            tooltip: tr('Fungua ELAPS AI', 'Open ELAPS AI'),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SizedBox(
                  height: MediaQuery.of(context).size.height * .7,
                  child: AiPanel(app: widget.app)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _i,
            backgroundColor: C.bgDeep,
            indicatorColor: C.rose.withOpacity(.4),
            onDestinationSelected: (v) => setState(() => _i = v),
            destinations: [
              for (final it in items)
                NavigationDestination(
                  icon: Icon(it.$1, color: C.muted),
                  selectedIcon: Icon(it.$1, color: Colors.white),
                  label: tr(it.$3, it.$2).split(' ').first,
                ),
            ],
          ),
        );
      }),
    );
  }
}
