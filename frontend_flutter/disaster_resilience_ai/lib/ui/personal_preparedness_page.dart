import 'package:flutter/material.dart';
import 'package:disaster_resilience_ai/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalPreparednessPage extends StatefulWidget {
  const PersonalPreparednessPage({super.key, required this.accessToken});
  final String accessToken;

  @override
  State<PersonalPreparednessPage> createState() => _PersonalPreparednessPageState();
}

class _PersonalPreparednessPageState extends State<PersonalPreparednessPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  // Checklist state
  List<dynamic> _items = [];
  double _score = 0;
  String _statusMessage = 'Needs Improvement';
  int _completedItems = 0;
  int _totalItems = 0;

  // Education state
  List<dynamic> _topics = [];
  bool _loadingTopics = false;

  static const _categoryIcons = {
    'supplies': Icons.inventory_2_outlined,
    'training': Icons.school_outlined,
    'planning': Icons.map_outlined,
    'general':  Icons.menu_book_outlined,
  };

  static const _categoryColors = {
    'supplies':  Color(0xFF1976D2),
    'training':  Color(0xFF388E3C),
    'planning':  Color(0xFFF57C00),
    'general':   Color(0xFF7B1FA2),
  };

  static const _categoryLabels = {
    'supplies': 'Supplies',
    'training': 'Training',
    'planning': 'Planning',
    'general':  'Learn & Read',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Silently refresh checklist when user returns to tab 0 — no spinner
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        _silentRefreshChecklist();
      }
    });
    _loadChecklist();
    _loadTopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklist() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.fetchChecklist(widget.accessToken);
      if (mounted) _applyChecklistData(data);
    } catch (e) {
      if (mounted) setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Refresh checklist data without showing the full-screen spinner.
  /// Used after toggling an item or returning from the Learn tab so the
  /// ExpansionTile doesn't collapse.
  Future<void> _silentRefreshChecklist() async {
    try {
      final data = await _api.fetchChecklist(widget.accessToken);
      if (mounted) _applyChecklistData(data);
    } catch (_) {}
  }

  void _applyChecklistData(Map<String, dynamic> data) {
    setState(() {
      _items          = data['items'] as List<dynamic>? ?? [];
      _score          = (data['score_percent'] as num?)?.toDouble() ?? 0;
      _statusMessage  = data['status_message'] as String? ?? 'Needs Improvement';
      _completedItems = (data['completed_items'] as num?)?.toInt() ?? 0;
      _totalItems     = (data['total_items'] as num?)?.toInt() ?? 0;
      _loading        = false;
    });
  }

  Future<void> _loadTopics() async {
    setState(() => _loadingTopics = true);
    try {
      final topics = await _api.fetchEducationalTopics(widget.accessToken);
      if (mounted) setState(() { _topics = topics; _loadingTopics = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTopics = false);
    }
  }

  Future<void> _toggleItem(String itemId, bool current) async {
    try {
      await _api.toggleChecklistItem(widget.accessToken, itemId, !current);
      _silentRefreshChecklist(); // silent — no spinner
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _markTopicViewed(String topicId) async {
    try {
      await _api.markTopicViewed(widget.accessToken, topicId);
      // Silent refreshes — keep the ExpansionTile open while data updates
      _silentRefreshChecklist();
      _silentRefreshTopics();
    } catch (_) {}
  }

  Future<void> _silentRefreshTopics() async {
    try {
      final topics = await _api.fetchEducationalTopics(widget.accessToken);
      if (mounted) setState(() => _topics = topics);
    } catch (_) {}
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Preparedness',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: 'My Checklist'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Learn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChecklistTab(), _buildEducationTab()],
      ),
    );
  }

  // ── Checklist Tab ──────────────────────────────────────────────────────────

  Widget _buildChecklistTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    if (_error != null) return _buildError(_loadChecklist);
    return RefreshIndicator(
      onRefresh: _loadChecklist,
      color: const Color(0xFF2E7D32),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScoreCard(),
          const SizedBox(height: 8),
          _buildLearnPrompt(),
          const SizedBox(height: 12),
          ..._buildGroupedItems(),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final color = _score >= 80
        ? const Color(0xFF2E7D32)
        : (_score >= 60 ? const Color(0xFFF57C00) : const Color(0xFFD32F2F));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Preparedness Score',
              style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('$_completedItems of $_totalItems completed',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${_score.toStringAsFixed(0)}%  •  $_statusMessage',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        SizedBox(
          width: 64, height: 64,
          child: CircularProgressIndicator(
            value: _score / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildLearnPrompt() {
    return GestureDetector(
      onTap: () => _tabController.animateTo(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCE93D8)),
        ),
        child: const Row(children: [
          Icon(Icons.menu_book_outlined, color: Color(0xFF7B1FA2), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Read the Learn articles to auto-complete the "Read" tasks',
              style: TextStyle(color: Color(0xFF4A148C), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Color(0xFF7B1FA2), size: 13),
        ]),
      ),
    );
  }

  List<Widget> _buildGroupedItems() {
    final Map<String, List<dynamic>> grouped = {};
    for (final item in _items) {
      final cat = item['category'] as String? ?? 'general';
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final widgets = <Widget>[];
    for (final cat in ['supplies', 'planning', 'training', 'general']) {
      if (!grouped.containsKey(cat)) continue;
      widgets.add(_buildCategoryHeader(cat, grouped[cat]!));
      for (final item in grouped[cat]!) {
        widgets.add(_buildChecklistItem(item as Map<String, dynamic>));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Widget _buildCategoryHeader(String category, List<dynamic> items) {
    final icon  = _categoryIcons[category]  ?? Icons.checklist_outlined;
    final color = _categoryColors[category] ?? const Color(0xFF7B1FA2);
    final label = _categoryLabels[category] ?? (category[0].toUpperCase() + category.substring(1));
    final done  = items.where((i) => i['completed'] == true).length;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const Spacer(),
        Text('$done/${items.length}',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final id            = item['id'] as String;
    final name          = item['item_name'] as String? ?? '';
    final completed     = item['completed'] as bool? ?? false;
    final linkedTopicId = item['linked_topic_id'] as String?;
    final isEducation   = linkedTopicId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? const Color(0xFFC8E6C9)
              : (isEducation ? const Color(0xFFE1BEE7) : Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: isEducation ? () => _tabController.animateTo(1) : null,
        leading: GestureDetector(
          onTap: isEducation ? null : () => _toggleItem(id, completed),
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? const Color(0xFF2E7D32) : Colors.transparent,
              border: Border.all(
                color: completed
                    ? const Color(0xFF2E7D32)
                    : (isEducation ? const Color(0xFF7B1FA2) : Colors.grey[400]!),
                width: 2,
              ),
            ),
            child: completed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
        ),
        title: Text(name, style: TextStyle(
          color: completed ? Colors.grey[500] : const Color(0xFF1E293B),
          decoration: completed ? TextDecoration.lineThrough : null,
          fontSize: 14,
        )),
        subtitle: isEducation
            ? Text(
                completed ? 'Completed — well done!' : 'Tap to read in Learn tab',
                style: TextStyle(
                  fontSize: 11,
                  color: completed ? Colors.green[600] : const Color(0xFF7B1FA2),
                ),
              )
            : null,
        trailing: isEducation
            ? Icon(Icons.arrow_forward_ios,
                color: completed ? Colors.green[400] : const Color(0xFF7B1FA2), size: 14)
            : null,
      ),
    );
  }

  // ── Education Tab ──────────────────────────────────────────────────────────

  Widget _buildEducationTab() {
    if (_loadingTopics) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    if (_topics.isEmpty) return const Center(
        child: Text('No educational content available', style: TextStyle(color: Colors.grey)));

    final categories = <String, List<dynamic>>{};
    for (final t in _topics) {
      final cat = t['category'] as String? ?? 'general';
      categories.putIfAbsent(cat, () => []).add(t);
    }

    final catLabels = {
      'before_flood': 'Before a Flood',
      'during_flood': 'During a Flood',
      'after_flood':  'After a Flood',
      'general':      'General Preparedness',
    };
    final catColors = {
      'before_flood': Colors.blue,
      'during_flood': Colors.orange,
      'after_flood':  Colors.teal,
      'general':      Colors.purple,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tip banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: const Row(children: [
            Icon(Icons.tips_and_updates_outlined, color: Color(0xFF2E7D32), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Expand and read an article — it automatically ticks the matching task in your checklist.',
                style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12),
              ),
            ),
          ]),
        ),
        ...categories.entries.map((entry) {
          final color = catColors[entry.key] ?? Colors.grey;
          final label = catLabels[entry.key] ?? entry.key;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label,
                  style: TextStyle(color: color[700], fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            ...entry.value.map((topic) => _buildTopicCard(topic as Map<String, dynamic>, color)),
            const SizedBox(height: 8),
          ]);
        }),
      ],
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, MaterialColor color) {
    final id          = topic['id'] as String;
    final title       = topic['title'] as String? ?? '';
    final description = topic['description'] as String? ?? '';
    final viewed      = topic['user_viewed'] as bool? ?? false;
    final links       = topic['external_links'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: viewed ? color[100]! : Colors.grey[200]!),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.menu_book_outlined, color: color[700], size: 20),
        ),
        title: Text(title,
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: viewed
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                const SizedBox(width: 4),
                Text('Done', style: TextStyle(
                    color: Colors.green[600], fontSize: 11, fontWeight: FontWeight.bold)),
              ])
            : const Icon(Icons.expand_more),
        onExpansionChanged: (expanded) {
          if (expanded && !viewed) _markTopicViewed(id);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic['content'] as String? ?? '',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Resources',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12)),
                const SizedBox(height: 4),
                ...links.map((link) {
                  final lnk   = link as Map<String, dynamic>;
                  final title = lnk['title'] as String? ?? '';
                  final url   = lnk['url'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: url.isNotEmpty ? () => _openLink(url) : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(Icons.open_in_new, size: 14, color: color[700]),
                          const SizedBox(width: 6),
                          Expanded(child: Text(title,
                              style: TextStyle(
                                  color: color[700],
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  decorationColor: color[400]))),
                        ]),
                      ),
                    ),
                  );
                }),
              ],
              if (!viewed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline, color: color[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Reading this article will tick the matching task in your checklist.',
                      style: TextStyle(color: color[700], fontSize: 11),
                    )),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(VoidCallback retry) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(_error ?? 'Error loading data',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: retry,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ));
  }
}
