import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/care_log_model.dart';
import '../utils/constants.dart';

class CareQuickActions extends StatelessWidget {
  final Function(CareType) onCareLogged;

  const CareQuickActions({
    super.key,
    required this.onCareLogged,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionConfig(type: CareType.water, color: AppColors.water, icon: Icons.water_drop),
      _ActionConfig(type: CareType.fertilize, color: AppColors.fertilize, icon: Icons.science),
      _ActionConfig(type: CareType.mist, color: AppColors.mist, icon: Icons.water),
      _ActionConfig(type: CareType.repot, color: AppColors.repot, icon: Icons.yard),
      _ActionConfig(type: CareType.prune, color: AppColors.prune, icon: Icons.content_cut),
      _ActionConfig(type: CareType.treat, color: AppColors.treat, icon: Icons.healing),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((config) {
        return Semantics(
          label: 'Log ${config.type.label}',
          button: true,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onCareLogged(config.type);
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: config.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(config.icon, color: config.color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    config.type.label,
                    style: AppTypography.caption.copyWith(
                      color: config.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionConfig {
  final CareType type;
  final Color color;
  final IconData icon;
  _ActionConfig({required this.type, required this.color, required this.icon});
}
