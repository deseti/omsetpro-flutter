import 'package:flutter/material.dart';
import '../models/profil_data_model.dart';
import '../components/profil_header.dart';
import '../components/personal_info_section.dart';
import '../components/password_section.dart';
import '../components/access_section.dart';
import '../../../widgets/responsive_widgets.dart';

class ProfilLayouts {
  static Widget buildMobileLayout(
    ProfilData profilData,
    Widget personalInfoSection,
    Widget passwordSection,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilHeader(profilData: profilData),
          const SizedBox(height: 24),
          personalInfoSection,
          const SizedBox(height: 24),
          passwordSection,
          const SizedBox(height: 24),
          AccessSection(profilData: profilData),
        ],
      ),
    );
  }

  static Widget buildTabletLayout(
    ProfilData profilData,
    Widget personalInfoSection,
    Widget passwordSection,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfilHeader(profilData: profilData),
              const SizedBox(height: 32),
              personalInfoSection,
              const SizedBox(height: 32),
              passwordSection,
              const SizedBox(height: 32),
              AccessSection(profilData: profilData),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDesktopLayout(
    ProfilData profilData,
    Widget personalInfoSection,
    Widget passwordSection,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil header di sebelah kiri
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    ProfilHeader(profilData: profilData),
                    const SizedBox(height: 32),
                    AccessSection(profilData: profilData),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Form fields di sebelah kanan
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    personalInfoSection,
                    const SizedBox(height: 32),
                    passwordSection,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
