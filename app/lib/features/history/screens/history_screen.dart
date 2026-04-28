import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'navHistory'.tr(),
              style: AppTextStyles.roleTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'historySubtitle'.tr(),
              style: AppTextStyles.roleSubtitle.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
