import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class SearchButtonsSection extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onReset;

  const SearchButtonsSection({
    super.key,
    required this.onSearch,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          // Reset Button - Secondary Action (Outlined)
          Expanded(
            flex: 1,
            child: CustomButton(
              text: 'Reset',
              icon: Icons.refresh_outlined,
              onPressed: onReset,
              type: ButtonType.outlined,
              height: 52,
            ),
          ),
          const SizedBox(width: 8),
          // Search Button - Primary Action (Filled)
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Filter Search',
              icon: Icons.filter_list_outlined,
              onPressed: onSearch,
              type: ButtonType.primary,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}
