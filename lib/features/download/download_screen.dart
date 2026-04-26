import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/cover.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/waveform.dart';

enum DlStage { idle, fetching, preview, downloading, done }

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});
  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _url =
      TextEditingController(text: 'https://youtu.be/dQw4w9WgXcQ');
  String _format = 'M4A';
  String _quality = '256';
  DlStage _stage = DlStage.idle;
  double _progress = 0;
  final Map<String, bool> _tags = {
    'title': false,
    'artist': false,
    'album': false,
    'genre': false,
    'cover': false,
  };
  Timer? _stepTimer;
  final _rng = math.Random();

  static const _meta = (
    title: 'Paper Radio',
    artist: 'Lianne Hoffmann',
    album: 'Softcore Cartography',
    genre: 'Ambient',
    duration: 198,
    seed: 27,
    tone: 'c-indigo',
  );

  @override
  void dispose() {
    _url.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  double _sizeFor(String f, String q) {
    final rates = {'128': 1.0, '256': 2.0, '320': 2.5};
    final mult = {'MP3': 1.0, 'M4A': 0.9, 'Opus': 0.6}[f]!;
    return (_meta.duration / 60.0) * rates[q]! * mult;
  }

  void _startFetch() {
    setState(() => _stage = DlStage.fetching);
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _stage = DlStage.preview);
    });
  }

  void _startDownload() {
    setState(() {
      _stage = DlStage.downloading;
      _progress = 0;
    });
    void step() {
      if (!mounted) return;
      setState(() {
        _progress = math.min(100, _progress + (2 + _rng.nextDouble() * 6));
      });
      if (_progress >= 100) {
        for (final entry in ['title', 'artist', 'album', 'genre', 'cover'].asMap().entries) {
          Timer(Duration(milliseconds: 200 + entry.key * 220), () {
            if (mounted) setState(() => _tags[entry.value] = true);
          });
        }
        Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _stage = DlStage.done);
        });
        return;
      }
      _stepTimer = Timer(const Duration(milliseconds: 120), step);
    }

    step();
  }

  void _reset() {
    setState(() {
      _stage = DlStage.idle;
      _url.clear();
      _progress = 0;
      for (final k in _tags.keys.toList()) {
        _tags[k] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final estSize = _sizeFor(_format, _quality);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          eyebrow: 'Download · local only',
          title: 'Add music',
          subtitle: 'Paste a URL · nothing leaves this device without asking',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UrlField(
                controller: _url,
                onClear: () => setState(() => _url.clear()),
              ),
              if (_stage == DlStage.idle)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: PrimaryButtonBlock(
                    label: 'Fetch metadata',
                    enabled: _url.text.trim().isNotEmpty,
                    onTap: _startFetch,
                  ),
                ),
              if (_stage == DlStage.fetching) const _FetchCard(),
              if (_stage == DlStage.preview ||
                  _stage == DlStage.downloading ||
                  _stage == DlStage.done) ...[
                const SizedBox(height: 14),
                _PreviewCard(),
                const SizedBox(height: 14),
                Text('FORMAT', style: AppType.sectionLabel()),
                const SizedBox(height: 6),
                _SegGroup(
                  options: const ['MP3', 'M4A', 'Opus'],
                  value: _format,
                  onChange: (v) => setState(() {
                    _format = v;
                    if (v == 'Opus' && _quality == '320') _quality = '256';
                  }),
                ),
                const SizedBox(height: 12),
                Text('QUALITY', style: AppType.sectionLabel()),
                const SizedBox(height: 6),
                _SegGroup(
                  options: const ['128', '256', '320'],
                  value: _quality,
                  onChange: (v) => setState(() => _quality = v),
                  disabled: (q) => _format == 'Opus' && q == '320',
                  trailingHint: (_) => 'kbps',
                ),
                const SizedBox(height: 18),
                _SizeRow(estSize: estSize),
                if (_stage == DlStage.preview)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: PrimaryButtonBlock(
                      label: 'Download · local only',
                      leading: Icons.download_outlined,
                      onTap: _startDownload,
                    ),
                  ),
                if (_stage == DlStage.downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ProgressBlock(
                      progress: _progress,
                      estSize: estSize,
                      format: _format,
                      quality: _quality,
                    ),
                  ),
                if (_stage == DlStage.done)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _DoneCard(
                      tags: _tags,
                      onAdd: _reset,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  const _UrlField({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 18, color: AppTokens.dim),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: AppTokens.accent(),
              style: AppType.mono(size: 13, color: AppTokens.fg),
              decoration: InputDecoration(
                hintText: 'youtube.com/...',
                hintStyle: AppType.mono(size: 13, color: AppTokens.dim2),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GhostButton(
              size: 32,
              onTap: onClear,
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

class _FetchCard extends StatefulWidget {
  const _FetchCard();
  @override
  State<_FetchCard> createState() => _FetchCardState();
}

class _FetchCardState extends State<_FetchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTokens.surface1,
            border: Border.all(color: AppTokens.hairline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) => Positioned(
                  top: _c.value * 60,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppTokens.accent(),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RESOLVING · 00:01',
                      style: AppType.mono(size: 12, color: AppTokens.dim, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('Reading remote stream…', style: AppType.body()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Cover(tone: 'c-indigo', seed: 27, size: 64, radius: 10, bars: 16),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Paper Radio',
                        style: AppType.sans(size: 16, weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('Lianne Hoffmann · Softcore Cartography',
                        style: AppType.caption(size: 12.5)),
                    const SizedBox(height: 6),
                    Text('${fmtDur(198)} · Ambient',
                        style: AppType.mono(size: 11, color: AppTokens.dim2, letterSpacing: 0.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 22,
            child: WaveformLine(
              seed: 27,
              bars: 64,
              height: 22,
              color: AppTokens.accent(),
              opacity: 0.85,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegGroup extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChange;
  final bool Function(String)? disabled;
  final String Function(String)? trailingHint;

  const _SegGroup({
    required this.options,
    required this.value,
    required this.onChange,
    this.disabled,
    this.trailingHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _SegBtn(
              label: options[i],
              hint: trailingHint?.call(options[i]),
              active: options[i] == value,
              disabled: disabled?.call(options[i]) ?? false,
              onTap: () => onChange(options[i]),
            ),
          ),
          if (i < options.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final String? hint;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  const _SegBtn({
    required this.label,
    required this.active,
    required this.disabled,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Opacity(
      opacity: disabled ? 0.3 : 1,
      child: Material(
        color: active ? AppTokens.accentSoft() : AppTokens.surface1,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled ? null : onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? accent : AppTokens.hairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppType.sans(
                      size: 13,
                      color: active ? accent : AppTokens.dim,
                    )),
                if (hint != null) ...[
                  const SizedBox(width: 4),
                  Text(hint!,
                      style: AppType.mono(
                        size: 10,
                        color: active ? accent : AppTokens.dim2,
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final double estSize;
  const _SizeRow({required this.estSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ESTIMATED SIZE', style: AppType.sectionLabel()),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: estSize.toStringAsFixed(1),
                      style: AppType.mono(size: 28, color: AppTokens.fg, letterSpacing: 0)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    TextSpan(
                      text: ' MB',
                      style: AppType.sans(size: 14, color: AppTokens.dim),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('STORAGE FREE', style: AppType.sectionLabel()),
              const SizedBox(height: 6),
              Text('24.3 GB',
                  style: AppType.mono(size: 14, color: AppTokens.dim)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final double progress;
  final double estSize;
  final String format;
  final String quality;

  const _ProgressBlock({
    required this.progress,
    required this.estSize,
    required this.format,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DOWNLOADING', style: AppType.mono(size: 12, color: AppTokens.dim, letterSpacing: 1)),
              Text('${progress.floor()}%',
                  style: AppType.mono(size: 12, color: accent, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: AppTokens.surface3,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    boxShadow: [
                      BoxShadow(color: AppTokens.accentSoft(), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(estSize * progress / 100).toStringAsFixed(1)} / ${estSize.toStringAsFixed(1)} MB',
                style: AppType.mono(size: 11, color: AppTokens.dim2, letterSpacing: 0.4),
              ),
              Text('$format · $quality kbps',
                  style: AppType.mono(size: 11, color: AppTokens.dim2, letterSpacing: 0.4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final Map<String, bool> tags;
  final VoidCallback onAdd;
  const _DoneCard({required this.tags, required this.onAdd});

  static const _labels = [
    ('title', 'Title', 'Paper Radio'),
    ('artist', 'Artist', 'Lianne Hoffmann'),
    ('album', 'Album', 'Softcore Cartography'),
    ('genre', 'Genre', 'Ambient'),
    ('cover', 'Cover art', 'embedded · 640×640'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check, size: 14, color: Color(0xFF0A0A0C)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Saved to library',
                        style: AppType.sans(size: 15, weight: FontWeight.w500)),
                    Text('Writing ID3 tags…', style: AppType.caption()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: AppTokens.surface2,
              child: Column(
                children: [
                  for (final entry in _labels)
                    _TagRow(
                      label: entry.$2,
                      value: entry.$3,
                      done: tags[entry.$1] ?? false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GhostButtonBlock(label: 'Add another', onTap: onAdd),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String label;
  final String value;
  final bool done;
  const _TagRow({required this.label, required this.value, required this.done});

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: done ? AppTokens.surface2 : AppTokens.surface1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: done ? accent : AppTokens.dim2,
              shape: BoxShape.circle,
              boxShadow: done
                  ? [BoxShadow(color: accent, blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label.toUpperCase(),
              style: AppType.mono(size: 10.5, color: AppTokens.dim, letterSpacing: 0.4),
            ),
          ),
          Expanded(
            child: Text(
              done ? value : 'pending',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppType.mono(
                size: 12.5,
                color: done ? AppTokens.fg : AppTokens.dim2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
