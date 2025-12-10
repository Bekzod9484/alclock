import 'package:flutter/material.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../utils/motivation_generator.dart';

/// Widget for inputting or displaying alarm motivation note
class MotivationNoteInput extends StatefulWidget {
  final String? initialNote;
  final ValueChanged<String?> onNoteChanged;

  const MotivationNoteInput({
    super.key,
    this.initialNote,
    required this.onNoteChanged,
  });

  @override
  State<MotivationNoteInput> createState() => _MotivationNoteInputState();
}

class _MotivationNoteInputState extends State<MotivationNoteInput> {
  late TextEditingController _controller;
  bool _hasUserInput = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
    _hasUserInput = widget.initialNote != null && widget.initialNote!.isNotEmpty;
    
    // If no initial note, assign random motivation after first frame
    if (!_hasUserInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          final randomNote = MotivationGenerator.randomMotivation();
          _controller.text = randomNote;
          widget.onNoteChanged(randomNote);
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.motivationNote ?? "Eslatma (majburiy emas)",
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        GlassCard(
          child: TextField(
            controller: _controller,
            maxLines: null,
            minLines: 1,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: l10n?.motivationNoteHint ?? "Eslatma kiriting...",
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              if (_isDisposed || !mounted) return;
              setState(() {
                _hasUserInput = value.isNotEmpty;
              });
              widget.onNoteChanged(value.isEmpty ? null : value);
            },
          ),
        ),
      ],
    );
  }
}

