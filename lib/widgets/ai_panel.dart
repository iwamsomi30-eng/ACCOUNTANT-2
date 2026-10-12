import 'package:flutter/material.dart';
import '../ai/elaps_engine.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import '../l10n.dart';

class _Msg {
  final String q;
  final AiReply r;
  int fb; // 0 = bado, 1 = 👍, -1 = inasubiri chaguo, 2 = imesahihishwa
  _Msg(this.q, this.r) : fb = r.needsChoice ? -1 : 0;
}

class AiPanel extends StatefulWidget {
  final AppState app;
  const AiPanel({super.key, required this.app});
  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> {
  final _q = TextEditingController();
  final List<_Msg> _chat = []; // mpya kwanza
  late final ElapsEngine _ai;

  List<String> _quick() => [
    tr('Jumla', 'Total'), tr('Hajalipa', 'Unpaid'), tr('Karibuni', 'Recent'),
    tr('Kanda inayoongoza', 'Top Zone'), tr('Muhtasari', 'Summary'), tr('Utabiri', 'Forecast')
  ];

  @override
  void initState() {
    super.initState();
    _ai = ElapsEngine.shared(widget.app);
    _ai.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Color _color(String k) => switch (k) {
        'warn' => C.amber,
        'ok' => C.green,
        'idea' => C.green,
        _ => C.sky,
      };

  IconData _icon(String k) => switch (k) {
        'warn' => Icons.warning_amber_rounded,
        'ok' => Icons.trending_up,
        'idea' => Icons.lightbulb_outline,
        _ => Icons.info_outline,
      };

  Widget _tile(String kind, String text) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: C.card,
          border: Border(left: BorderSide(color: _color(kind), width: 3)),
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(_icon(kind), size: 16, color: _color(kind)),
          const SizedBox(width: 6),
          Expanded(child: t(text, size: 12)),
        ]),
      );

  Widget _miniChip(String label, VoidCallback onTap) => ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        backgroundColor: C.card,
        side: const BorderSide(color: C.border),
        onPressed: onTap,
      );

  Widget _feedbackRow(_Msg m) {
    if (!m.r.learnable) return const SizedBox.shrink();
    if (m.fb == 1) {
      return tl(context, 'Asante — nimejifunza kutokana na jibu hili.', 'Thank you — I learned from this answer.',
          color: C.green, size: 10.5);
    }
    if (m.fb == 2) {
      return tl(context, 'Nimesahihishwa na kujifunza. Asante!', 'Corrected and learned. Thank you!', color: C.green, size: 10.5);
    }
    if (m.fb == -1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        tl(context, 'Samahani. Ulimaanisha nini?', 'Sorry. What did you mean?', color: C.muted, size: 10.5),
        Wrap(spacing: 6, children: [
          for (final a in m.r.alts) _miniChip(a.label, () => _correct(m, a.id)),
        ]),
      ]);
    }
    return Row(children: [
      if (m.r.intentLabel.isNotEmpty)
        Expanded(
          child: t(
              tr('Nia: ${m.r.intentLabel} · ${(m.r.confidence * 100).round()}%', 'Intent: ${m.r.intentLabel} · ${(m.r.confidence * 100).round()}%'),
              color: C.muted,
              size: 10.5),
        )
      else
        const Spacer(),
      InkWell(
        onTap: () => _thumbUp(m),
        child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.thumb_up_alt_outlined, size: 14, color: C.muted)),
      ),
      InkWell(
        onTap: () => setState(() => m.fb = -1),
        child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.thumb_down_alt_outlined, size: 14, color: C.muted)),
      ),
    ]);
  }

  Widget _qa(_Msg m, {required bool latest}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4, left: 30),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: C.cViolet, borderRadius: BorderRadius.circular(12)),
              child: Text(m.q,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: C.card,
              border: Border.all(color: C.border, width: .8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SelectableText(m.r.text,
                  style: const TextStyle(fontSize: 12, color: C.text, height: 1.35)),
              const SizedBox(height: 4),
              _feedbackRow(m),
            ]),
          ),
          if (latest && m.r.followUps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(spacing: 6, children: [
                for (final f in m.r.followUps) _miniChip(f, () => _send(f)),
              ]),
            )
          else
            const SizedBox(height: 6),
        ],
      );

  void _send([String? preset]) {
    final q = (preset ?? _q.text).trim();
    if (q.isEmpty) return;
    setState(() {
      _chat.insert(0, _Msg(q, _ai.ask(q)));
      _q.clear();
    });
  }

  Future<void> _thumbUp(_Msg m) async {
    setState(() => m.fb = 1);
    await _ai.learn(m.q, m.r.intentId);
    if (mounted) setState(() {});
  }

  Future<void> _correct(_Msg m, String intentId) async {
    setState(() => m.fb = 2);
    await _ai.learn(m.q, intentId);
    if (!mounted) return;
    setState(() => _chat.insert(0, _Msg(m.q, _ai.ask(m.q, forceIntent: intentId))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.bgDeep,
        border: Border(left: BorderSide(color: C.border, width: .8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipOval(
                child: Image.asset('assets/badger.png',
                    width: 34, height: 34, fit: BoxFit.cover)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                tl(context, 'ELAPS AI', 'ELAPS AI', bold: true, size: 14),
                t(
                    _ai.neuralReady
                        ? tr('Msaidizi mahiri · ML + Deep NN', 'Smart assistant · ML + Deep NN')
                        : tr('Msaidizi mahiri · inajiandaa…', 'Smart assistant · preparing…'),
                    color: C.muted,
                    size: 11),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              if (_chat.isEmpty)
                t(
                    tr('Uliza kwa Kiswahili chochote kuhusu jumla, Jumuiya au Kanda. Mfano: "Benedict amelipa kiasi gani?", "nani hajalipa?", "makusanyo ya wiki hii".', 'Ask anything about totals, communities or zones. Example: "How much did Benedict pay?", "who is unpaid?", "collections this week".'),
                    color: C.muted,
                    size: 12),
              for (var i = 0; i < _chat.length; i++) _qa(_chat[i], latest: i == 0),
              if (_chat.isNotEmpty) const Divider(),
              for (final tip in widget.app.tips()) _tile(tip.kind, tip.text),
            ]),
          ),
          Wrap(spacing: 6, runSpacing: 0, children: [
            for (final c in _quick()) _miniChip(c, () => _send(c)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: _q,
            onSubmitted: (_) => _send(),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('Uliza ELAPS AI…', 'Ask ELAPS AI…'),
              hintStyle: const TextStyle(fontSize: 12, color: C.muted),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.send, size: 16, color: C.navy),
                  onPressed: () => _send()),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: C.border)),
            ),
          ),
        ],
      ),
    );
  }
}
