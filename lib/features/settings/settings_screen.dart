import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/seed_data.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/oklch.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/visualizer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _visualizers = [
    (VizStyle.spectrum, 'Spectrum bars', 'Classic analyzer'),
    (VizStyle.waveform, 'Waveform pulse', 'Track shape · beat-driven'),
    (VizStyle.monolith, 'Monolith LEDs', 'Segmented towers'),
    (VizStyle.gradient, 'Gradient rings', 'Radial color · concentric pulse'),
    (VizStyle.oscilloscope, 'Oscilloscope', 'Electronic signal · glow'),
  ];

  static const _swatches = <(double, String)>[
    (340, 'Magenta'),
    (20, 'Ember'),
    (60, 'Sodium'),
    (150, 'Moss'),
    (200, 'Ice'),
    (280, 'Violet'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final accent = AppTokens.accent();
    final previewTrack = state.currentTrack;
    final totalSize = kLibrary.fold<double>(0, (s, t) => s + t.size);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: GhostButton(
            onTap: () => state.navigate(AppRoute.library),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const ScreenHeader(
          eyebrow: 'Personalize · saved on device',
          title: 'Settings',
          subtitle: 'Tune how Monolith looks and behaves',
        ),

        // ── Live preview ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 90,
                    color: const Color(0x05FFFFFF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Visualizer(
                      style: state.vizStyle,
                      seed: previewTrack.seed,
                      progress: 0.35,
                      height: 84,
                      accent: accent,
                      playing: true,
                      interactive: false,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LIVE PREVIEW',
                        style: AppType.mono(
                          size: 10, color: AppTokens.dim2, letterSpacing: 1,
                        )),
                    Text(
                      '${_vizName(state.vizStyle).toUpperCase()} · ${state.variant.toUpperCase()}',
                      style: AppType.mono(
                        size: 10, color: AppTokens.dim2, letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Visual direction (Safe / Bold) ──
        _SettingGroup(
          label: 'Visual direction',
          hint: 'Presets that flip several knobs at once',
          child: Row(
            children: [
              Expanded(
                child: _VariantCard(
                  active: state.variant == 'safe',
                  name: 'Safe',
                  desc: 'Clean MD3 · grid library · linear waveform',
                  onTap: () => state.setVariant('safe'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VariantCard(
                  active: state.variant == 'bold',
                  name: 'Bold',
                  desc: 'Spectrum shelf · radial player · waveform-as-UI',
                  onTap: () => state.setVariant('bold'),
                ),
              ),
            ],
          ),
        ),

        // ── Library ──
        _SettingGroup(
          label: 'Library',
          child: _SettingRow(
            title: 'Layout',
            value: state.libraryGrid ? 'Grid' : 'Shelf',
            child: _SegPicker(
              value: state.libraryGrid ? 'grid' : 'shelf',
              options: const [('shelf', 'Shelf'), ('grid', 'Grid')],
              onChange: (v) => state.setLibraryGrid(v == 'grid'),
            ),
          ),
        ),

        // ── Now playing ──
        _SettingGroup(
          label: 'Now playing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingRow(
                title: 'Layout',
                value: state.nowPlayingRadial
                    ? 'Radial · circular'
                    : 'Linear · stacked',
                child: _SegPicker(
                  value: state.nowPlayingRadial ? 'radial' : 'linear',
                  options: const [('linear', 'Linear'), ('radial', 'Radial')],
                  onChange: (v) =>
                      state.setNowPlayingRadial(v == 'radial'),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Visualizer',
                    style: AppType.sans(size: 13, color: AppTokens.fg)),
              ),
              for (final v in _visualizers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _VizRow(
                    style: v.$1,
                    label: v.$2,
                    note: v.$3,
                    active: state.vizStyle == v.$1,
                    accent: accent,
                    onTap: () => state.setVizStyle(v.$1),
                  ),
                ),
            ],
          ),
        ),

        // ── Accent color ──
        _SettingGroup(
          label: 'Accent color',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: [
                  for (final s in _swatches)
                    _AccentSwatch(
                      hue: s.$1,
                      name: s.$2,
                      active: state.accentHue == s.$1,
                      onTap: () => state.setAccentHue(s.$1),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CUSTOM HUE',
                      style: AppType.mono(
                        size: 11, color: AppTokens.dim, letterSpacing: 0.4,
                      )),
                  Text('${state.accentHue.round()}°',
                      style: AppType.mono(
                        size: 11, color: AppTokens.dim, letterSpacing: 0.4,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              _HueSlider(
                value: state.accentHue,
                onChange: state.setAccentHue,
              ),
            ],
          ),
        ),

        // ── Storage ──
        _SettingGroup(
          label: 'Storage',
          child: Column(
            children: [
              _AboutRow(
                label: 'Library',
                value:
                    '${kLibrary.length} tracks · ${totalSize.toStringAsFixed(1)} MB',
              ),
              const SizedBox(height: 6),
              const _AboutRow(label: 'Mode', value: '100% on device'),
              const SizedBox(height: 6),
              const _AboutRow(label: 'Network', value: 'only when downloading'),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(
            child: Text(
              'MONOLITH · v1.0 · LOCAL',
              style: AppType.mono(
                size: 10, color: AppTokens.dim2, letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _vizName(VizStyle s) => switch (s) {
        VizStyle.spectrum => 'spectrum',
        VizStyle.waveform => 'waveform',
        VizStyle.monolith => 'monolith',
        VizStyle.gradient => 'gradient',
        VizStyle.oscilloscope => 'oscilloscope',
      };
}

// ── Building blocks ───────────────────────────────────────────────────────

class _SettingGroup extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  const _SettingGroup({required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppType.mono(
                size: 10.5, color: AppTokens.dim2, letterSpacing: 1.4,
              )),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(hint!, style: AppType.caption(size: 12)),
            ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String? value;
  final Widget child;
  const _SettingRow({required this.title, this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(title, style: AppType.sans(size: 14, color: AppTokens.fg)),
              if (value != null)
                Text(value!,
                    style: AppType.mono(
                      size: 11, color: AppTokens.dim, letterSpacing: 0.2,
                    )),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SegPicker extends StatelessWidget {
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChange;
  const _SegPicker({
    required this.value,
    required this.options,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.surface3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(o.$1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == o.$1 ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    o.$2,
                    style: AppType.sans(
                      size: 13,
                      weight: FontWeight.w500,
                      color: value == o.$1
                          ? const Color(0xFF0A0A0C)
                          : AppTokens.dim,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final bool active;
  final String name;
  final String desc;
  final VoidCallback onTap;
  const _VariantCard({
    required this.active,
    required this.name,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Material(
      color: active ? AppTokens.accentSoft() : AppTokens.surface1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? accent : AppTokens.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _Radio(active: active),
                  const SizedBox(width: 10),
                  Text(name,
                      style: AppType.sans(size: 15, weight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Text(desc,
                  style: AppType.mono(
                    size: 11.5, color: AppTokens.dim, letterSpacing: 0.1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _VizRow extends StatelessWidget {
  final VizStyle style;
  final String label;
  final String note;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _VizRow({
    required this.style,
    required this.label,
    required this.note,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTokens.accentSoft() : AppTokens.surface1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? accent : AppTokens.hairline,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 64,
                  height: 36,
                  color: const Color(0x66000000),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  child: Visualizer(
                    style: style,
                    seed: 11 + label.codeUnitAt(0),
                    progress: 0.4,
                    height: 36,
                    accent: accent,
                    playing: true,
                    interactive: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: AppType.sans(size: 14, color: AppTokens.fg)),
                    const SizedBox(height: 1),
                    Text(note,
                        style: AppType.mono(
                          size: 11.5, color: AppTokens.dim, letterSpacing: 0.2,
                        )),
                  ],
                ),
              ),
              _Radio(active: active),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final double hue;
  final String name;
  final bool active;
  final VoidCallback onTap;
  const _AccentSwatch({
    required this.hue,
    required this.name,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatchColor = oklch(0.72, 0.22, hue);
    final accent = AppTokens.accent();
    return Material(
      color: active ? AppTokens.accentSoft() : AppTokens.surface1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? accent : AppTokens.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: swatchColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.sans(
                    size: 12, weight: FontWeight.w500, color: AppTokens.fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChange;
  const _HueSlider({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      for (var h = 0; h <= 360; h += 40) oklch(0.72, 0.22, h.toDouble()),
    ];
    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                ),
                border: Border.all(color: AppTokens.hairline),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 14,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                pressedElevation: 4,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              min: 0,
              max: 360,
              value: value.clamp(0, 360),
              onChanged: onChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool active;
  const _Radio({required this.active});

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? accent : AppTokens.dim,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: active
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTokens.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppType.sans(size: 13, color: AppTokens.fg)),
          Text(value,
              style: AppType.mono(
                size: 11.5, color: AppTokens.dim, letterSpacing: 0.2,
              )),
        ],
      ),
    );
  }
}
