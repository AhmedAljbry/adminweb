import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:triing/Core/AppConfig.dart';
import 'package:triing/Core/AppNotifications/AppNotifications.dart';
import 'package:triing/Core/servies/services_locator.dart';

import 'package:triing/genertcode/presentation/manager/gen_code_bloc.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_event.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_state.dart';
import 'package:triing/genertcode/presentation/pages/AleataarScreen.dart';
import 'package:triing/genertcode/presentation/pages/GenerateIdsScreen.dart';
import 'package:triing/genertcode/presentation/pages/LamsatdawaScreen.dart';

class Home extends StatelessWidget {
  final AppConfigController configController;

  const Home({super.key, required this.configController});

  static const List<String> _titles = <String>[
    "سم النحل",
    "لمسة دواء",
    "العطار",
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = configController.config;
    print('🏠 [HOME] بناء واجهة Home');

    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: cfg.primaryColor,
      brightness: cfg.useDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Roboto',
    );

    // إنشاء إعدادات التطبيقات الثلاثة
    final AppConfig sumifunConfig = configController.config.copyWith(
      appTitle: "سم النحل",
      brandName: "سم النحل",
      logoUrl: "image/sumifun.png",
      collection: "ids",
      document: "Sumifun",
      file: "سم النحل",
      primaryColor: const Color(0xFF25A1CE),
    );

    final AppConfig lamstConfig = configController.config.copyWith(
      appTitle: "لمسة دواء",
      brandName: "لمسة دواء",
      logoUrl: "image/limage.jpg",
      collection: "lamsaids",
      document: "لمسة دواء",
      file: "لمسة دواء",
      primaryColor: const Color(0xFF2E7D32),
    );

    final AppConfig altConfig = configController.config.copyWith(
      appTitle: "العطار",
      brandName: "العطار",
      logoUrl: "image/limage.jpg",
      collection: "aleataarids",
      document: "العطار",
      file: " العطار",
      primaryColor: const Color(0xFF6A1B9A),
    );

    final AppConfigController sumifunController =
    AppConfigController()..update(sumifunConfig);
    final AppConfigController lamstController =
    AppConfigController()..update(lamstConfig);
    final AppConfigController altController =
    AppConfigController()..update(altConfig);

    final pages = <Widget>[
      GenerateIdsScreen(configController: sumifunController),
      Lamsatdawascreen(configController: lamstController),
      Aleataarscreen(configController: altController),
    ];

    return BlocProvider<GenCodeBloc>(
      create: (_) {
        final bloc = sl<GenCodeBloc>();
        bloc.add(const StartConnectivityWatch());
        bloc.add(const TryResumeFromDisk()); // لو حابب يستأنف من القرص
        return bloc;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedBuilder(
          animation: configController,
          builder: (context, _) {
            return Theme(
              data: theme,
              child: BlocBuilder<GenCodeBloc, GenCodeState>(
                builder: (context, state) {
                  final int currentIndex = state.selectedIndex;

                  return Scaffold(
                    backgroundColor: Colors.white,
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      title: Text(
                        _titles[currentIndex],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          tooltip: 'اختبار الإشعارات',
                          onPressed: () async {
                            await AppNotifications.showSimple(
                              id: AppNotifications.idGeneral,
                              title: 'اختبار الإشعارات',
                              body: 'الإشعارات تعمل بنجاح ✅',
                            );
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                        ),
                        IconButton(
                          tooltip: 'تبديل السمة',
                          onPressed: configController.toggleTheme,
                          icon: const Icon(Icons.brightness_6),
                        ),
                        IconButton(
                          tooltip: 'الإعدادات',
                          onPressed: () => _openSettingsSheet(context),
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    body: pages[currentIndex],
                    bottomNavigationBar: NavigationBar(
                      selectedIndex: currentIndex,
                      onDestinationSelected: (idx) {
                        context.read<GenCodeBloc>().add(ItemTappedEvent(idx));
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          label: "سم النحل",
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.local_pharmacy),
                          label: "لمسة دواء",
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.spa_outlined),
                          label: "العطار",
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSettingsSheet(BuildContext context) {
    // TODO: نفّذ BottomSheet الإعدادات كما تريد
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'الإعدادات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('ضع إعدادات التطبيق هنا...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
