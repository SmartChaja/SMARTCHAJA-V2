import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:smart_chaja/localization/app_locale.dart';

class ChargingStationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String searchQuery;
  final VoidCallback? onClear;
  final bool isLoading;

  const ChargingStationSearchField({
    super.key,
    required this.controller,
    required this.searchQuery,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<ChargingStationSearchField> createState() =>
      _ChargingStationSearchFieldState();
}

class _ChargingStationSearchFieldState
    extends State<ChargingStationSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_focusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      },
      child: GestureDetector(
        onTap: () {
          // Unfocus when tapping outside the search field
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
          }
        },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedOpacity(
                opacity: widget.isLoading ? 0.7 : _fadeAnimation.value,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    // Prevent the parent GestureDetector from unfocusing when tapping on the search field itself
                    _focusNode.requestFocus();
                  },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isFocused
                            ? [
                                Colors.white,
                                const Color(0xFFF8F9FF),
                              ]
                            : [
                                Colors.white,
                                const Color(0xFFFAFAFA),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _isFocused
                            ? const Color(0xFF2196F3).withOpacity(0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isFocused
                              ? const Color(0xFF2196F3).withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: _isFocused ? 12 : 8,
                          offset: const Offset(0, 4),
                          spreadRadius: _isFocused ? 2 : 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.9),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Search Icon with Animation
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isFocused
                                  ? const Color(0xFF2196F3).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: _isFocused
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF6B7280),
                              size: 22,
                            ),
                          ),
                        ),
                        
                        // Text Field
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocale.searchForChargingStations
                                  .getString(context),
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 4,
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _focusNode.unfocus(),
                          ),
                        ),
                        
                        // Clear Button (only shows when there's text)
                        if (widget.searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildClearButton(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onClear,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}