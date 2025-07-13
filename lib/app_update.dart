import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:woosh/services/update_service.dart';

/// Create a page to prompt user to update app
class UpdateWidget extends StatefulWidget {
  const UpdateWidget({super.key});

  static String routeName = 'update';
  static String routePath = '/update';

  @override
  State<UpdateWidget> createState() => _UpdateWidgetState();
}

class _UpdateWidgetState extends State<UpdateWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String _latestVersion;
  late List<String> _features;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUpdateInfo();
  }

  void _loadUpdateInfo() {
    final updateInfo = UpdateService.getUpdateInfo();
    _latestVersion = updateInfo['latestVersion'];
    _features = List<String>.from(updateInfo['features']);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Icon(
                      Icons.system_update_alt,
                      color: Colors.blue,
                      size: 60,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 32, 0, 16),
                  child: Text(
                    'Update Available',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                  child: Text(
                    'A new version of the app is available with exciting features and important bug fixes.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'What\'s New:',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              Text(
                                'Version 2.1.0',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureItem(
                                'Enhanced performance and faster loading times',
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureItem(
                                'New dark mode theme option',
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureItem(
                                'Improved security and privacy features',
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureItem(
                                'Bug fixes and stability improvements',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 32, 0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            print('Update Now pressed');
                            // TODO: Implement update functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Update Now',
                            style: GoogleFonts.interTight(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            print('Remind Me Later pressed');
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Remind Me Later',
                            style: GoogleFonts.interTight(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                  child: Text(
                    'This update is recommended for the best app experience. You can update now or be reminded later.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 2, 0, 0),
          child: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
