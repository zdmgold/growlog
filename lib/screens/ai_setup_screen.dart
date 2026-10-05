import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai/ai_client.dart';
import '../services/ai/ai_providers.dart';
import '../services/ai/ai_settings.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Pick a provider, paste a key, tap Connect. The app tests the key and picks
/// a working model by itself.
class AiSetupScreen extends StatefulWidget {
  const AiSetupScreen({super.key});

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  final _settings = AiSettings.instance;
  final _keyController = TextEditingController();
  AiProvider? _selected;
  bool _busy = false;
  bool _showKey = false;
  String _status = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = _settings.provider;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() => _keyController.text = text);
    }
  }

  Future<void> _openKeyPage(AiProvider p) async {
    final ok = await launchUrl(
      Uri.parse(p.keyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open ${p.keyUrl} in your browser.')),
      );
    }
  }

  Future<void> _connect() async {
    final p = _selected;
    if (p == null || _busy) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Starting…';
    });
    try {
      await _settings.connect(
        p,
        _keyController.text,
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      if (!mounted) return;
      _keyController.clear();
      setState(() {
        _busy = false;
        _status = '';
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '';
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '';
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _disconnect() async {
    await _settings.disconnect();
    if (!mounted) return;
    setState(() {
      _selected = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Connect AI')),
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
            ),
            children: [
              Text(
                'Scanning and chat use an AI provider you choose. Paste your key '
                'and tap Connect.',
                style: AppTypography.body.copyWith(color: sub),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoCard(
                isDark: isDark,
                icon: PhosphorFill.lockKey,
                text:
                    'Your key is stored encrypted on this phone. It is sent only '
                    'to the provider you pick, never to us. When you scan, your '
                    'photo goes to that provider too, under their terms.',
              ),
              if (_settings.isConfigured) ...[
                const SizedBox(height: AppSpacing.md),
                _ConnectedCard(
                  settings: _settings,
                  isDark: isDark,
                  onDisconnect: _disconnect,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                _settings.isConfigured ? 'Switch provider' : 'Choose a provider',
                style: AppTypography.title1.copyWith(color: ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final p in aiProviders)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ProviderTile(
                    provider: p,
                    isDark: isDark,
                    selected: _selected?.id == p.id,
                    connected:
                        _settings.isConfigured && _settings.provider?.id == p.id,
                    onTap: () => setState(() {
                      _selected = p;
                      _error = null;
                    }),
                    child: _selected?.id == p.id ? _keyForm(p, isDark) : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _keyForm(AiProvider p, bool isDark) {
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _keyController,
          obscureText: !_showKey,
          enabled: !_busy,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _connect(),
          decoration: InputDecoration(
            hintText: 'Paste your ${p.name} key',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _showKey ? 'Hide key' : 'Show key',
                  icon: Icon(_showKey ? PhosphorRegular.eyeSlash : PhosphorRegular.eye),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
                IconButton(
                  tooltip: 'Paste',
                  icon: const Icon(PhosphorRegular.clipboard),
                  onPressed: _paste,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _openKeyPage(p),
              icon: const Icon(PhosphorRegular.arrowSquareOut, size: 18),
              label: const Text('Get a key'),
            ),
            const Spacer(),
            Text(p.hint, style: AppTypography.caption.copyWith(color: sub)),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _error!,
              style: AppTypography.footnote.copyWith(
                color: isDark ? AppColors.errorDark : AppColors.error,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _busy ? null : _connect,
            child: _busy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(PhosphorBold.plugsConnected, size: 20),
                      const SizedBox(width: 8),
                      const Text('Connect'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;
  const _InfoCard({required this.isDark, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.footnote.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final AiSettings settings;
  final bool isDark;
  final VoidCallback onDisconnect;
  const _ConnectedCard({
    required this.settings,
    required this.isDark,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final ok = isDark ? AppColors.successDark : AppColors.success;
    final models = {
      ...settings.candidates,
      if (settings.model != null) settings.model!,
    }.toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: ok.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorFill.checkCircle, color: ok, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to ${settings.provider?.name ?? ''}',
                  style: AppTypography.title2.copyWith(color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (models.length > 1)
            DropdownButtonFormField<String>(
              value: settings.model,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Model'),
              items: [
                for (final m in models)
                  DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (m) {
                if (m != null) settings.selectModel(m);
              },
            )
          else
            Text('Model: ${settings.model}',
                style: AppTypography.footnote.copyWith(color: sub)),
          const SizedBox(height: AppSpacing.sm),
          if (!settings.supportsVision)
            Text(
              'This model could chat but could not read photos, so scanning is '
              'off. Pick another model above or switch provider.',
              style: AppTypography.footnote.copyWith(
                color: isDark ? AppColors.warningDark : AppColors.watchText,
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDisconnect,
              child: const Text('Remove key'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final AiProvider provider;
  final bool isDark;
  final bool selected;
  final bool connected;
  final VoidCallback onTap;
  final Widget? child;

  const _ProviderTile({
    required this.provider,
    required this.isDark,
    required this.selected,
    required this.connected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;

    return Material(
      color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected ? PhosphorFill.checkCircle : PhosphorRegular.plugsConnected,
                    size: 22,
                    color: selected ? accent : sub,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      provider.name,
                      style: AppTypography.title2.copyWith(color: ink),
                    ),
                  ),
                  if (connected)
                    Text('Connected',
                        style: AppTypography.caption.copyWith(color: accent)),
                ],
              ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
