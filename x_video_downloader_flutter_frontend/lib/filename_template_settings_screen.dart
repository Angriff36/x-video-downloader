import 'package:flutter/material.dart';
import 'filename_template.dart';

/// Settings screen for configuring custom filename templates.
///
/// Allows users to:
/// - Select from predefined presets
/// - Edit custom templates with live preview
/// - Configure per-platform template overrides
/// - View all available placeholders
class FilenameTemplateSettingsScreen extends StatefulWidget {
  const FilenameTemplateSettingsScreen({super.key});

  @override
  State<FilenameTemplateSettingsScreen> createState() =>
      _FilenameTemplateSettingsScreenState();
}

class _FilenameTemplateSettingsScreenState
    extends State<FilenameTemplateSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _templateController;
  String _currentTemplate = '';
  String? _validationError;

  // Per-platform overrides
  final Map<String, TextEditingController> _platformControllers = {};
  final Map<String, String> _platformTemplates = {};
  final Map<String, bool> _platformExpanded = {};

  static const _platforms = [
    'YouTube',
    'Instagram',
    'TikTok',
    'X/Twitter',
    'Vimeo',
    'Facebook',
    'Reddit',
    'Dailymotion',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentTemplate = FilenameTemplate.current;
    _templateController = TextEditingController(text: _currentTemplate);

    // Load per-platform templates
    for (final platform in _platforms) {
      final override = FilenameTemplate.getForPlatform(platform);
      _platformTemplates[platform] = override ?? '';
      _platformControllers[platform] = TextEditingController(
        text: override ?? '',
      );
      _platformExpanded[platform] = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _templateController.dispose();
    for (final controller in _platformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateTemplate(String value) {
    setState(() {
      _currentTemplate = value;
      _validationError = FilenameTemplate.validate(value);
    });
    if (_validationError == null) {
      FilenameTemplate.set(value);
    }
  }

  void _applyPreset(String template) {
    _templateController.text = template;
    _updateTemplate(template);
  }

  void _resetToDefault() {
    FilenameTemplate.reset();
    final defaultTmpl = FilenameTemplate.defaultTemplate;
    _templateController.text = defaultTmpl;
    setState(() {
      _currentTemplate = defaultTmpl;
      _validationError = null;
    });
  }

  Future<void> _savePlatformOverride(String platform) async {
    final value = _platformControllers[platform]!.text.trim();
    if (value.isEmpty) {
      await FilenameTemplate.removeForPlatform(platform);
      setState(() {
        _platformTemplates[platform] = '';
      });
    } else {
      await FilenameTemplate.setForPlatform(platform, value);
      setState(() {
        _platformTemplates[platform] = value;
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value.isEmpty
                ? 'Removed $platform override'
                : 'Saved $platform template',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filename Templates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Template'),
            Tab(text: 'Presets'),
            Tab(text: 'Per-Platform'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateTab(),
          _buildPresetsTab(),
          _buildPerPlatformTab(),
        ],
      ),
    );
  }

  Widget _buildTemplateTab() {
    final preview = FilenameTemplate.preview(_currentTemplate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current template editor
          Text(
            'Filename Template',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _templateController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'e.g. {platform} - {title}',
              errorText: _validationError,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Reset to default',
                    onPressed: _resetToDefault,
                  ),
                ],
              ),
            ),
            onChanged: _updateTemplate,
          ),
          const SizedBox(height: 16),

          // Live preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$preview.mp4',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available placeholders
          Text(
            'Available Placeholders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...FilenameTemplate.placeholders.map((p) => _buildPlaceholderChip(p)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderChip(PlaceholderInfo placeholder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          final insertion = '{${placeholder.tag}}';
          final text = _templateController.text;
          final selection = _templateController.selection;
          final newText = text.replaceRange(
            selection.start.clamp(0, text.length),
            selection.end.clamp(0, text.length),
            insertion,
          );
          _templateController.text = newText;
          _templateController.selection = TextSelection.collapsed(
            offset:
                (selection.start >= 0 ? selection.start : text.length) +
                insertion.length,
          );
          _updateTemplate(newText);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '{${placeholder.tag}}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  placeholder.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              Icon(Icons.add, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: FilenameTemplate.presets.length,
      itemBuilder: (context, index) {
        final preset = FilenameTemplate.presets[index];
        final isSelected = _currentTemplate == preset.template;
        final preview = FilenameTemplate.preview(preset.template);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                isSelected
                    ? const BorderSide(color: Colors.blue, width: 2)
                    : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              _templateController.text = preset.template;
              _applyPreset(preset.template);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color:
                                    isSelected
                                        ? Colors.blue
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$preview.mp4',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ignore: deprecated_member_use
                  Radio<String>(
                    value: preset.template,
                    // ignore: deprecated_member_use
                    groupValue: _currentTemplate,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        _templateController.text = value;
                        _applyPreset(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerPlatformTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Platform-Specific Templates',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Override the global template for specific platforms. '
          'Leave empty to use the global template.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ..._platforms.map((platform) => _buildPlatformCard(platform)),
      ],
    );
  }

  Widget _buildPlatformCard(String platform) {
    final hasOverride = _platformTemplates[platform]?.isNotEmpty == true;
    final preview = FilenameTemplate.preview(
      _platformTemplates[platform]?.isNotEmpty == true
          ? _platformTemplates[platform]!
          : _currentTemplate,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: _platformExpanded[platform] ?? false,
        onExpansionChanged: (expanded) {
          setState(() => _platformExpanded[platform] = expanded);
        },
        leading: Icon(
          _platformIcon(platform),
          color: hasOverride ? Colors.blue : Colors.grey,
        ),
        title: Row(
          children: [
            Text(platform),
            const SizedBox(width: 8),
            if (hasOverride)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '$preview.mp4',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _platformControllers[platform],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Use global template ($_currentTemplate)',
                    suffixIcon:
                        hasOverride
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Remove override',
                              onPressed: () {
                                _platformControllers[platform]!.clear();
                                _savePlatformOverride(platform);
                              },
                            )
                            : null,
                  ),
                  onSubmitted: (_) => _savePlatformOverride(platform),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _savePlatformOverride(platform),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'YouTube':
        return Icons.play_circle_filled;
      case 'Instagram':
        return Icons.camera_alt;
      case 'TikTok':
        return Icons.music_note;
      case 'X/Twitter':
        return Icons.tag;
      case 'Vimeo':
        return Icons.videocam;
      case 'Facebook':
        return Icons.thumb_up;
      case 'Reddit':
        return Icons.forum;
      case 'Dailymotion':
        return Icons.movie;
      default:
        return Icons.language;
    }
  }
}
