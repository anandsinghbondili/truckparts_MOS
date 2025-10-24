import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/app_context_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () =>
              NavigationUtils.safePop(context, fallbackRoute: AppRouter.home),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contact_support_outlined, size: 24),
            const SizedBox(width: 8),
            const Text('Contact Us'),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRouter.home),
          ),
          // Company Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Image.asset(
              'assets/logos/shortform.png',
              fit: BoxFit.contain,
              height: 24,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppContextService.companyNameFull,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get in touch with our support team',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contact Methods
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Methods',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Card
                  _buildContactCard(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    subtitle: 'Call us for immediate assistance',
                    value:
                        'Admin: ${AppContextService.adminName} - ${AppContextService.adminPhoneFormatted}',
                    onTap: () => _makePhoneCall(
                      context,
                      AppContextService.adminPhoneDialable,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email Card
                  _buildContactCard(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'Send us your queries via email',
                    value: AppContextService.adminEmail,
                    onTap: () =>
                        _sendEmail(context, AppContextService.adminEmail),
                  ),

                  const SizedBox(height: 12),

                  // WhatsApp Card
                  _buildContactCard(
                    context,
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp Support',
                    subtitle: 'Chat with us on WhatsApp',
                    value:
                        'Admin: ${AppContextService.adminName} - ${AppContextService.adminPhoneFormatted}',
                    onTap: () => _openWhatsApp(
                      context,
                      AppContextService.adminPhoneDialable,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Admin Contact Card
                  _buildContactCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'Admin Contact',
                    subtitle: 'Reach out to our administrator',
                    value:
                        '${AppContextService.adminName} - ${AppContextService.adminPhoneFormatted}',
                    onTap: () => _makePhoneCall(
                      context,
                      AppContextService.adminPhoneDialable,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location Card
                  _buildContactCard(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Visit Us',
                    subtitle: 'Our registered office location',
                    value:
                        'Door No. 3-6-436, Naspur Building, Himayat Nagar, Hyderabad, Telangana - 500 029',
                    onTap: () => _openMaps(context),
                  ),

                  const SizedBox(height: 12),

                  // Business Hours
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Business Hours',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBusinessHourRow(
                            'Monday - Friday',
                            '9:00 AM - 6:00 PM',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          _buildBusinessHourRow(
                            'Saturday',
                            '9:00 AM - 1:00 PM',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          _buildBusinessHourRow('Sunday', 'Closed'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHourRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          hours,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            message: 'Unable to make phone call',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error making phone call: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Support Request - Truck Parts App'},
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            message: 'Unable to open email client',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error opening email: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(context, message: 'Unable to open WhatsApp');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error opening WhatsApp: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Door+No.+3-6-436+Naspur+Building+Himayat+Nagar+Hyderabad+Telangana+500020',
    );
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(context, message: 'Unable to open maps');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Error opening maps: ${e.toString()}',
        );
      }
    }
  }
}
