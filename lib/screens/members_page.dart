import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../l10n.dart';

/// Majina ya watoa michango wa kila Jumuiya + namba za simu.
/// Jumuiya isiyo na majina inabaki wazi; unaweza kuongeza au kurekebisha wakati wowote.
class MembersPage extends StatefulWidget {
  final AppState app;
  const MembersPage({super.key, required this.app});
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  int _sel = 0;
  String _q = '';

  Future<void> _edit(Kanda k, String j, {Member? m}) async {
    final name = TextEditingController(text: m?.name ?? '');
    final phone = TextEditingController(text: m?.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card,
        title: Text(m == null ? tr('Ongeza jina', 'Add name') : tr('Rekebisha jina', 'Edit name'),
            style: const TextStyle(color: C.text, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('Jina kamili', 'Full name')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: tr('Namba ya simu', 'Phone number')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Ghairi', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Hifadhi', 'Save'))),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    if (m == null) {
      await widget.app.addMember(k.name, j, name.text, phone.text);
    } else {
      await widget.app.editMember(m, name.text, phone.text);
    }
  }

  Future<void> _delete(Kanda k, String j, Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card,
        title: Text(tr('Futa jina hili?', 'Delete this name?'), style: const TextStyle(color: C.text, fontSize: 16)),
        content: Text(m.name, style: const TextStyle(color: C.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Hapana', 'No'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Futa', 'Delete'))),
        ],
      ),
    );
    if (ok == true) await widget.app.removeMember(k.name, j, m);
  }

  Widget _jumuiya(Kanda k, String j, int idx) {
    final list = widget.app.membersFor(k.name, j);
    final q = _q.toLowerCase();
    final shown = q.isEmpty
        ? list
        : list.where((m) => m.name.toLowerCase().contains(q) || m.phone.contains(q)).toList();
    if (q.isNotEmpty && shown.isEmpty && !j.toLowerCase().contains(q)) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: cardBox(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${k.name}|$j|$q'),
          initiallyExpanded: q.isNotEmpty,
          iconColor: C.muted,
          collapsedIconColor: C.muted,
          title: t('${idx + 1}. $j', bold: true, size: 13.5),
          subtitle: t(
              list.isEmpty
                  ? tr('Majina hayajajazwa', 'No names yet')
                  : tr('Majina ${list.length}', '${list.length} names'),
              size: 11.5,
              color: list.isEmpty ? C.amber : C.muted),
          children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: t(tr('Wazi - ongeza majina wakati wowote.', 'Empty - add names any time.'),
                        size: 12, color: C.muted)),
              ),
            for (var i = 0; i < shown.length; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: C.soft,
                    child: t('${list.indexOf(shown[i]) + 1}', size: 11, color: C.navy)),
                title: t(shown[i].name, size: 13.5),
                subtitle: t(shown[i].phone.isEmpty ? tr('Hakuna simu', 'No phone') : shown[i].phone,
                    size: 12, color: shown[i].phone.isEmpty ? C.amber : C.muted),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: tr('Rekebisha', 'Edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _edit(k, j, m: shown[i])),
                  IconButton(
                      tooltip: tr('Futa', 'Delete'),
                      icon: const Icon(Icons.delete_outline, size: 18, color: C.danger),
                      onPressed: () => _delete(k, j, shown[i])),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _edit(k, j),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: Text(tr('Ongeza jina', 'Add name')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = kSeedKanda[_sel];
    return LayoutBuilder(builder: (context, cons) {
      final narrow = cons.maxWidth < kNarrow;
      return ListView(
        padding: EdgeInsets.fromLTRB(narrow ? 16 : 14, narrow ? 18 : 14, narrow ? 16 : 14, narrow ? 100 : 14),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: tl(context, 'Majina ya Watoa Michango', 'Contributors', bold: true, size: 18)),
            tl(context, 'Jumla: ${widget.app.memberCount}', 'Total: ${widget.app.memberCount}', color: C.muted, size: 12),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _sel,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: tr('Kanda', 'Zone'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              for (var i = 0; i < kSeedKanda.length; i++)
                DropdownMenuItem(value: i, child: Text('${i + 1}. ${kSeedKanda[i].name}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _sel = v ?? 0),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: tr('Tafuta jina au simu', 'Search name or phone'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.border)),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < k.jumuiya.length; i++) _jumuiya(k, k.jumuiya[i], i),
        ],
      );
    });
  }
}
