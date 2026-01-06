import 'package:flutter/material.dart';

class CustomDropdownMenu extends StatelessWidget {
  final List<CustomDropdownItem> menuItems;
  final Function(dynamic) onSelected;
  final Widget? icon;
  final Color iconColor;
  final Color? backgroundColor;
  final Color? itemTextColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;

  const CustomDropdownMenu({
    super.key,
    required this.menuItems,
    required this.onSelected,
    this.icon = const Icon(Icons.more_vert),
    this.iconColor = Colors.white, // Default to white for main menu icon
    this.backgroundColor,
    this.itemTextColor,
    this.iconSize = 24.0,
    this.padding,
    this.elevation = 8.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return PopupMenuButton(
      icon: icon,
      iconSize: iconSize,
      color: backgroundColor ?? theme.cardColor,
      elevation: elevation,
      padding: padding ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      itemBuilder: (context) => menuItems.map((item) {
        return PopupMenuItem(
          value: item.value,
          enabled: item.enabled,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  // Use item's iconColor if specified, otherwise use black as default for menu items
                  color: item.iconColor ?? Colors.black, 
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: itemTextColor ?? theme.textTheme.bodyLarge?.color,
                    fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (item.trailing != null) item.trailing!,
            ],
          ),
        );
      }).toList(),
      onSelected: onSelected,
      iconColor: iconColor, // This sets the color for the main dropdown menu icon
    );
  }
}

class CustomDropdownItem {
  final String title;
  final dynamic value;
  final IconData? icon;
  final Color? iconColor; // This can override the default black color
  final bool enabled;
  final bool isBold;
  final Widget? trailing;

  CustomDropdownItem({
    required this.title,
    required this.value,
    this.icon,
    this.iconColor, // Default will be black (set in the widget build method)
    this.enabled = true,
    this.isBold = false,
    this.trailing,
  });
}