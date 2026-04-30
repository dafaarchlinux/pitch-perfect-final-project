import 'package:flutter/material.dart';

import '../../services/practice_progress_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);

  final TextEditingController suggestionController = TextEditingController();
  final TextEditingController impressionController = TextEditingController();

  bool isSubmitting = false;
  bool isLoadingHistory = true;
  String? editingCreatedAt;
  List<Map<String, dynamic>> feedbackHistory = [];

  @override
  void initState() {
    super.initState();
    _loadFeedbackHistory();
  }

  @override
  void dispose() {
    suggestionController.dispose();
    impressionController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackHistory() async {
    final history = await PracticeProgressService.getHistory();

    if (!mounted) return;

    setState(() {
      feedbackHistory = history.where((item) {
        return item['type']?.toString() == 'Saran & Kesan TPM';
      }).toList();
      isLoadingHistory = false;
    });
  }

  Future<void> _submitFeedback() async {
    final suggestion = suggestionController.text.trim();
    final impression = impressionController.text.trim();

    if (suggestion.isEmpty && impression.isEmpty) {
      _showMessage('Isi saran atau kesan terlebih dahulu.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    if (editingCreatedAt == null) {
      await PracticeProgressService.addPracticeSession(
        title: 'Saran & Kesan TPM',
        type: 'Saran & Kesan TPM',
        score: null,
        level: null,
        combo: null,
        passed: true,
        metadata: {
          'suggestion': suggestion,
          'impression': impression,
          'source': 'Feedback Screen',
        },
      );
    } else {
      await PracticeProgressService.updateHistoryItem(
        createdAt: editingCreatedAt!,
        title: 'Saran & Kesan TPM',
        type: 'Saran & Kesan TPM',
        score: null,
        level: null,
        combo: null,
        passed: true,
        metadata: {
          'suggestion': suggestion,
          'impression': impression,
          'source': 'Feedback Screen',
        },
      );
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
      editingCreatedAt = null;
      suggestionController.clear();
      impressionController.clear();
    });

    await _loadFeedbackHistory();
    _showMessage('Saran dan kesan berhasil disimpan.');
  }

  void _editFeedback(Map<String, dynamic> item) {
    final metadata = item['metadata'] is Map
        ? Map<String, dynamic>.from(item['metadata'])
        : <String, dynamic>{};

    setState(() {
      editingCreatedAt = item['created_at']?.toString();
      impressionController.text = metadata['impression']?.toString() ?? '';
      suggestionController.text = metadata['suggestion']?.toString() ?? '';
    });
  }

  Future<void> _deleteFeedback(Map<String, dynamic> item) async {
    final createdAt = item['created_at']?.toString();
    if (createdAt == null || createdAt.isEmpty) return;

    await PracticeProgressService.deleteHistoryItem(createdAt);
    await _loadFeedbackHistory();

    _showMessage('Saran dan kesan dihapus.');
  }

  void _cancelEdit() {
    setState(() {
      editingCreatedAt = null;
      suggestionController.clear();
      impressionController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(String? rawDate) {
    final date = DateTime.tryParse(rawDate ?? '');
    if (date == null) return 'Waktu tidak tersedia';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _inputCard({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _cyan),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF7E84A8)),
              filled: true,
              fillColor: _surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _cyan, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final metadata = item['metadata'] is Map
        ? Map<String, dynamic>.from(item['metadata'])
        : <String, dynamic>{};

    final impression = metadata['impression']?.toString() ?? '';
    final suggestion = metadata['suggestion']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: _cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(item['created_at']?.toString()),
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editFeedback(item),
                icon: const Icon(Icons.edit_rounded),
                color: _purple,
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _deleteFeedback(item),
                icon: const Icon(Icons.delete_outline_rounded),
                color: _pink,
                tooltip: 'Hapus',
              ),
            ],
          ),
          if (impression.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Kesan',
              style: TextStyle(color: _text, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              impression,
              style: const TextStyle(color: _muted, height: 1.4),
            ),
          ],
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Saran',
              style: TextStyle(color: _text, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion,
              style: const TextStyle(color: _muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historySection() {
    if (isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: CircularProgressIndicator(color: _purple),
        ),
      );
    }

    if (feedbackHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: const Text(
          'Belum ada saran atau kesan tersimpan.',
          style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(children: feedbackHistory.map(_historyCard).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Saran & Kesan TPM'),
        centerTitle: true,
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeedbackHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, Color(0xFF2563EB), _pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  editingCreatedAt == null
                      ? 'Tulis kesan dan saran untuk mata kuliah TPM.'
                      : 'Kamu sedang mengedit masukan yang sudah tersimpan.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _inputCard(
                title: 'Kesan',
                hint: 'Contoh: Materi TPM membantu memahami aplikasi mobile.',
                icon: Icons.favorite_rounded,
                controller: impressionController,
              ),
              const SizedBox(height: 16),
              _inputCard(
                title: 'Saran',
                hint: 'Contoh: Tambahkan contoh implementasi API dan database.',
                icon: Icons.lightbulb_rounded,
                controller: suggestionController,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submitFeedback,
                  icon: Icon(
                    editingCreatedAt == null
                        ? Icons.save_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    editingCreatedAt == null
                        ? 'Simpan Masukan'
                        : 'Simpan Perubahan',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              if (editingCreatedAt != null) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Batalkan Edit'),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Riwayat Masukan',
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _historySection(),
            ],
          ),
        ),
      ),
    );
  }
}
