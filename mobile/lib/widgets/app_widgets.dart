// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/constants.dart';

// ── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? iconColor;

  const StatCard({
    super.key, required this.label, required this.value,
    this.unit, required this.icon, this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor ?? const Color(AppConstants.primaryColor), size: 22),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Color(AppConstants.textPrimary))),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(unit!,
                      style: const TextStyle(fontSize: 13, color: Color(AppConstants.textSecondary))),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
              style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(AppConstants.textPrimary))),
        if (action != null) action!,
      ],
    );
  }
}

// ── Macro Chip ────────────────────────────────────────────────────────────────
class MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MacroChip({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ── Loading Button ────────────────────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const LoadingButton({
    super.key, required this.text, required this.loading, this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(text),
      ),
    );
  }
}

// ── Meal Slot Card ────────────────────────────────────────────────────────────
class MealSlotCard extends StatelessWidget {
  final String slot;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MealSlotCard({super.key, required this.slot, required this.calories,
      required this.protein, required this.carbs, required this.fat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _slotIcon(),
                const SizedBox(width: 8),
                Text(slot[0].toUpperCase() + slot.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const Spacer(),
                Text('${calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                    fontSize: 15,
                  )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MacroChip(label: 'Protein', value: '${protein.toStringAsFixed(0)}g', color: Colors.blue),
                MacroChip(label: 'Carbs',   value: '${carbs.toStringAsFixed(0)}g',   color: Colors.orange),
                MacroChip(label: 'Fat',     value: '${fat.toStringAsFixed(0)}g',     color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotIcon() {
    final icons = {
      'breakfast': (Icons.wb_sunny_outlined, Colors.orange),
      'lunch':     (Icons.restaurant,         Colors.blue),
      'snack':     (Icons.apple,               Colors.green),
      'dinner':    (Icons.nights_stay_outlined, Colors.indigo),
    };
    final (icon, color) = icons[slot] ?? (Icons.restaurant, Colors.grey);
    return Icon(icon, color: color, size: 20);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: Color(AppConstants.textSecondary))),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }
}

// ── Plan Date Section ─────────────────────────────────────────────────────────
class PlanDateSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;

  const PlanDateSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                           'Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _pick(BuildContext context, DateTime? initial,
      ValueChanged<DateTime> onChanged) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && context.mounted) onChanged(picked);
  }

  void _preset(int days) {
    final start = startDate ?? DateTime.now();
    onStartChanged(start);
    onEndChanged(start.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final duration = (startDate != null && endDate != null)
        ? endDate!.difference(startDate!).inDays : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Quick presets
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          const Text('Duration:',
            style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
          const SizedBox(width: 8),
          for (final (label, days) in [
            ('4 weeks', 28), ('6 weeks', 42), ('8 weeks', 56),
            ('3 months', 91), ('6 months', 182),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _preset(days),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(AppConstants.primaryColor).withValues(alpha: 0.25)),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 11,
                    color: Color(AppConstants.primaryColor), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      // Start → End row
      Row(children: [
        Expanded(child: _dateField(context, 'Start date', startDate, onStartChanged)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
        ),
        Expanded(child: _dateField(context, 'End date', endDate, onEndChanged)),
        if (duration != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text('$duration d',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
          ),
        ],
      ]),
    ]);
  }

  Widget _dateField(BuildContext context, String hint, DateTime? date,
      ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () => _pick(context, date, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 13,
            color: date != null ? const Color(AppConstants.primaryColor) : Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(
            date != null ? _fmt(date) : hint,
            style: TextStyle(fontSize: 12,
              color: date != null
                  ? const Color(AppConstants.textPrimary) : Colors.grey.shade400),
          )),
        ]),
      ),
    );
  }
}

// ── YouTube Video Dialog ──────────────────────────────────────────────────────
class VideoSheet extends StatefulWidget {
  final String exerciseName;
  final String videoId;
  const VideoSheet({super.key, required this.exerciseName, required this.videoId});
  @override
  State<VideoSheet> createState() => _VideoSheetState();
}

class _VideoSheetState extends State<VideoSheet> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.fitness_center, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.exerciseName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(controller: _controller),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.info_outline, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Tap fullscreen for best viewing',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Error Message ─────────────────────────────────────────────────────────────
class ErrorMessage extends StatelessWidget {
  final String message;
  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ],
      ),
    );
  }
}
