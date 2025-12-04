import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final String textCancel;
  final String textConfirm;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.textCancel = "Batal",
    this.textConfirm = "Ya",
    this.confirmColor = AppColors.primary,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          color: confirmColor == Colors.red
              ? AppColors.statusDanger
              : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            textCancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(
            textConfirm,
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

void showAppDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirm,
  String textConfirm = "Ya",
  Color confirmColor = AppColors.primary,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      content: content,
      onConfirm: onConfirm,
      textConfirm: textConfirm,
      confirmColor: confirmColor,
    ),
  );
}
