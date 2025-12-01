import 'package:flutter/material.dart';
import 'package:triing/Core/AppConfig.dart';

/// -------- 1) نموذج إعدادات ديناميكي -------

/// -------- 2) الصفحة الرئيسية ديناميكية --------
/// هذه الواجهة “قابلة للحقن” بدوالّك الحالية:
/// - onGenerate: نفس handleGenerateAndSave
/// - onStop: نفس stopProcess
class GenerateCodesPage extends StatefulWidget {
  final AppConfigController configController;

  // الحالات الحالية من منطقك (تربطها ببزنس لوجِكك)
  final TextEditingController countController;
  final bool isExcelSaving;
  final bool isFirestoreSaving;
  final double excelProgress;
  final double firestoreProgress;

  final VoidCallback onGenerate;
  final VoidCallback onStop;

  const GenerateCodesPage({
    super.key,
    required this.configController,
    required this.countController,
    required this.isExcelSaving,
    required this.isFirestoreSaving,
    required this.excelProgress,
    required this.firestoreProgress,
    required this.onGenerate,
    required this.onStop,
  });

  @override
  State<GenerateCodesPage> createState() => _GenerateCodesPageState();
}

class _GenerateCodesPageState extends State<GenerateCodesPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final cfg = widget.configController.config;

    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: cfg.primaryColor,
      brightness: cfg.useDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Roboto', // غيّر الخط لو تحب
    );

    final isBusy = widget.isExcelSaving || widget.isFirestoreSaving;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: widget.configController,
        builder: (context, _) {
          final c = widget.configController.config;
          return Theme(
            data: theme,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  c.brandName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    tooltip: 'تبديل السمة',
                    onPressed: widget.configController.toggleTheme,
                    icon: const Icon(Icons.brightness_6),
                  ),
                  IconButton(
                    tooltip: 'الإعدادات',
                    onPressed: () => _openSettingsSheet(context),
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // شعار مع حامل
                        _BrandLogo(url: c.logoUrl),
                        const SizedBox(height: 20),

                        // العنوان الديناميكي
                        Text(
                          c.appTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'تأكد من اختيار الرقم لتوليد العملية، حيث لا يمكن إيقاف التوليد بعد البدء.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // نموذج مع تحقّق
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: widget.countController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "أدخل عدد المعرفات",
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'أدخل رقماً صحيحاً';
                              }
                              final n = int.tryParse(value);
                              if (n == null || n <= 0) {
                                return 'العدد يجب أن يكون أكبر من 0';
                              }
                              if (n > 1000000) {
                                return 'العدد كبير جداً، قلّله من فضلك';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // أزرار الإجراءات
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: isBusy
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    widget.onGenerate();
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "توليد وحفظ المعرفات",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isBusy ? widget.onStop : null,
                                icon: const Icon(Icons.stop_circle),
                                label: const Text("إيقاف التحميل"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                      color: isBusy
                                          ? Colors.red
                                          : Colors.grey.shade300),
                                  foregroundColor:
                                  isBusy ? Colors.red : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // بطاقات التقدم
                        if (widget.isExcelSaving)
                          _ProgressCard(
                            title: "جاري إنشاء ملف Excel...",
                            value: widget.excelProgress,
                          ),
                        if (widget.isFirestoreSaving)
                          _ProgressCard(
                            title: "جاري رفع البيانات إلى Firestore...",
                            value: widget.firestoreProgress,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: 1,
                onDestinationSelected: (_) {},
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined), label: "سم النحل"),
                  NavigationDestination(
                      icon: Icon(Icons.local_pharmacy), label: "لمسة دواء"),
                  NavigationDestination(
                      icon: Icon(Icons.spa_outlined), label: "العطار"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// أسفل-الصفحة: إعدادات لتعديل الاسم/الشعار/اللون مباشرة
  void _openSettingsSheet(BuildContext context) {
    final c = widget.configController.config;
    final titleCtrl = TextEditingController(text: c.appTitle);
    final brandCtrl = TextEditingController(text: c.brandName);
    final logoCtrl = TextEditingController(text: c.logoUrl);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                const Text(
                  'الإعدادات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم التطبيق (AppBar)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الرئيسي',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: logoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط الشعار (Logo URL)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // ألوان سريعة
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in [
                      const Color(0xFF2E7D32),
                      const Color(0xFF0D47A1),
                      const Color(0xFF6A1B9A),
                      const Color(0xFFEF6C00),
                      const Color(0xFF00897B),
                    ])
                      GestureDetector(
                        onTap: () {
                          widget.configController.update(
                            widget.configController.config
                                .copyWith(primaryColor: color),
                          );
                        },
                        child: CircleAvatar(radius: 16, backgroundColor: color),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    widget.configController.update(
                      widget.configController.config.copyWith(
                        brandName: brandCtrl.text.trim().isEmpty
                            ? null
                            : brandCtrl.text.trim(),
                        appTitle: titleCtrl.text.trim().isEmpty
                            ? null
                            : titleCtrl.text.trim(),
                        logoUrl: logoCtrl.text.trim().isEmpty
                            ? null
                            : logoCtrl.text.trim(),
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ الإعدادات'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// -------- 3) عناصر مساعدة للتصميم --------

class _BrandLogo extends StatelessWidget {
  final String url;
  const _BrandLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2/1, // مربع
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            color: Colors.white,
          ),
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/placeholder.png', // ضع أي صورة خفيفة
            image: url,
            fit: BoxFit.contain,
            imageErrorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 10, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final double value;
  const _ProgressCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0, 1) * 100).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text("$percent%"),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: value.clamp(0, 1)),
          ],
        ),
      ),
    );
  }
}
