import 'package:flutter/material.dart';
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/plan/model/plan.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback? onTap;
  final Function(Plan?)? onRadioChanged;
  final Plan? selectedPlan;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.canAfford,
    this.onTap,
    this.onRadioChanged,
    this.selectedPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Radio Button
              Transform.scale(
                scale: 1.0,
                child: Radio<Plan>(
                  value: plan,
                  groupValue: selectedPlan,
                  onChanged: onRadioChanged,
                  activeColor: AppColors.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (!canAfford) return Colors.grey.shade400;
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primaryColor;
                    }
                    return Colors.grey.shade500;
                  }),
                ),
              ),

              const SizedBox(width: AppSpacing.small),

              // Plan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: canAfford
                            ? (isSelected
                                ? AppColors.primaryColor
                                : Colors.black87)
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                          ),
                          child: Text(
                            '${plan.price.toStringAsFixed(2)} ${plan.currency}',
                            style: AppTextStyles.bodyText2.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : (canAfford
                                      ? Colors.black87
                                      : Colors.grey.shade500),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!canAfford) ...[
                          const SizedBox(width: AppSpacing.small),
                          Text(
                            'Low balance',
                            style: AppTextStyles.bodyText2.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
