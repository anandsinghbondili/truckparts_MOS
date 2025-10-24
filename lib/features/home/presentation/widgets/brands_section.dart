import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BrandsSection extends StatelessWidget {
  final Function(String) onBrandSelected;

  const BrandsSection({super.key, required this.onBrandSelected});

  /// Helper function to get the correct asset path for brand logos
  String _getBrandLogoPath(String brandName) {
    // Map brand names to their actual file names to handle special characters
    final brandFileMap = {
      'KAR VALVES': 'KAR VALVES.png',
      'TALBROS QHT': 'TALBROS QHT.png',
      'BANCO': 'BANCO.png',
      'GOETZE': 'GOETZE.png',
      'JMP': 'JMP.png',
      'KSPG': 'KSPG.png',
      'LEYPARTS': 'LEYPARTS.png',
      'MAHLE': 'MAHLE.png',
      'RBL': 'RBL.png',
      'SETCO': 'SETCO.png',
      'SPICER': 'SPICER.png',
      'SVL': 'SVL.png',
      'TALBROS': 'TALBROS.png',
      'TIGER POWER': 'TIGER POWER.png',
      'USHA': 'USHA.png',
    };

    final fileName = brandFileMap[brandName] ?? '$brandName.png';
    return 'assets/images/brand_logos/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    // Static list of brands with available logos - Load immediately
    final brandsWithLogos = [
      'BANCO',
      'GOETZE',
      'JMP',
      'KAR VALVES',
      'KSPG',
      'LEYPARTS',
      'MAHLE',
      'RBL',
      'SETCO',
      'SPICER',
      'SVL',
      'TALBROS QHT',
      'TALBROS',
      'TIGER POWER',
      'USHA',
    ];

    print(
      '🏷️ BrandsSection: Displaying ${brandsWithLogos.length} brands immediately',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Our Brands',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brandsWithLogos.length,
              itemBuilder: (context, index) {
                final brandName = brandsWithLogos[index];
                return GestureDetector(
                  onTap: () => onBrandSelected(brandName),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        _getBrandLogoPath(brandName),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Failed to load brand logo: $brandName');
                          debugPrint('Error: $error');

                          // Fallback to brand name if logo not found
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                brandName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
