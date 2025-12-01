import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triing/Core/AppConfig.dart';
import 'package:triing/Core/utils/enum.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_bloc.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_event.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_state.dart';

class Lamsatdawascreen extends StatefulWidget {
  final AppConfigController configController; // نفس الـ instance في كل مرة
  const Lamsatdawascreen({super.key, required this.configController});

  @override
  State<Lamsatdawascreen> createState() => _LamsatdawascreenState();
}

class _LamsatdawascreenState extends State<Lamsatdawascreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _countCtrl;
  late final TextEditingController _collectionCtrl;
  late final TextEditingController _fileCtrl;
  late final TextEditingController _documentCtrl;

  bool _shownSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    final c = widget.configController.config;

    // نقرأ القيم بدايةً مرة واحدة
    _countCtrl = TextEditingController(text: c.countStr);
    _collectionCtrl = TextEditingController(text: c.collection);
    _fileCtrl = TextEditingController(text: c.file);
    _documentCtrl = TextEditingController(text: c.document);
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _collectionCtrl.dispose();
    _fileCtrl.dispose();
    _documentCtrl.dispose();
    super.dispose();
  }

  // تزامن ناعم مع الإعدادات (لا نكسر كتابة المستخدم)
  void _maybeSyncFormWithConfig(AppConfig cfg, {required bool isBusy}) {
    // لا نكتب فوق المستخدم إذا فيه فوكس على أي حقل أو العملية شغالة
    final hasFocus = WidgetsBinding.instance.focusManager.primaryFocus != null &&
        WidgetsBinding.instance.focusManager.primaryFocus!.hasFocus;
    if (hasFocus || isBusy) return;

    if (_countCtrl.text != cfg.countStr) _countCtrl.text = cfg.countStr;
    if (_collectionCtrl.text != cfg.collection) {
      _collectionCtrl.text = cfg.collection;
    }
    if (_fileCtrl.text != cfg.file) _fileCtrl.text = cfg.file;
    if (_documentCtrl.text != cfg.document) {
      _documentCtrl.text = cfg.document;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: widget.configController, // يسمع لأي update()
        builder: (context, _) {
          final cfg = widget.configController.config;

          final theme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: cfg.primaryColor,
              brightness: cfg.useDark ? Brightness.dark : Brightness.light,
            ),
            fontFamily: 'Roboto',
          );

          return Theme(
            data: theme,
            child: BlocConsumer<GenCodeBloc, GenCodeState>(
              listener: (context, state) async {
                // تشغيل جديد → صفّر الفلاغ
                if (state.isRunning && state.batchState == RequestState.loading) {
                  _shownSuccessDialog = false;
                }

                if (state.batchState == RequestState.error &&
                    state.message.isNotEmpty) {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('حدث خطأ'),
                      content: Text(state.message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('موافق'),
                        )
                      ],
                    ),
                  );
                }

                if (state.batchState == RequestState.loaded &&
                    state.result != null &&
                    !_shownSuccessDialog) {
                  _shownSuccessDialog = true;

                  final result = state.result!;
                  final path = result.savedExcelPath ?? 'غير متوفر';

                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('تم إنشاء الملف بنجاح'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'عدد المعرّفات المطلوبة: ${result.requestedCount}'),
                          Text(
                              'تم رفعها إلى Firestore: ${result.uploadedToFirestore}'),
                          const SizedBox(height: 8),
                          const Text(
                            'مسار ملف Excel:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            path,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يمكنك نسخ المسار وفتح الملف من مدير الملفات.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('موافق'),
                        ),
                      ],
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isBusy = state.isRunning;

                // حدّث الحقول من الإعدادات بلطف (لو ما فيه كتابة/انشغال)
                _maybeSyncFormWithConfig(cfg, isBusy: isBusy);

                Future<void> _onGenerate() async {
                  if (!state.isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا يوجد اتصال بالإنترنت')),
                    );
                    return;
                  }
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
                  final collection = _collectionCtrl.text.trim();
                  final file = _fileCtrl.text.trim();
                  final document = _documentCtrl.text.trim();

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('تأكيد البدء'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('عدد المعرّفات: $count'),
                          Text('Collection: $collection'),
                          Text('ملف (Excel): $file'),
                          Text('Document: $document'),
                          const SizedBox(height: 8),
                          const Text('هل تريد المتابعة؟'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('متابعة'),
                        ),
                      ],
                    ),
                  ) ??
                      false;

                  if (!confirmed) return;

                  context.read<GenCodeBloc>().add(
                    StartBatchRequested(
                      count: count,
                      collection: collection,
                      file: file,
                      document: document,
                    ),
                  );
                }

                Future<void> _onStop() async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('إيقاف العملية'),
                      content:
                      const Text('هل تريد إيقاف العملية الجارية؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('إيقاف'),
                        ),
                      ],
                    ),
                  ) ??
                      false;

                  if (!confirmed) return;
                  context.read<GenCodeBloc>().add(const StopBatchEvent());
                }

                return Scaffold(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  body: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // صورة ديناميكية مع مفتاح لتجديد الودجت عند تغيّر الرابط
                            _BrandLogo(
                              url: cfg.logoUrl,
                              key: ValueKey(cfg.logoUrl),
                            ),
                            const SizedBox(height: 20),

                            // العنوان من الإعدادات ويُحدث فوراً
                            Text(
                              cfg.appTitle,
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

                            // الفورم
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _countCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "أدخل عدد المعرفات",
                                      prefixIcon: const Icon(Icons.numbers),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _collectionCtrl,
                                    decoration: InputDecoration(
                                      labelText: "Collection (Firestore)",
                                      prefixIcon:
                                      const Icon(Icons.cloud_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'هذا الحقل مطلوب'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _fileCtrl,
                                    decoration: InputDecoration(
                                      labelText: "اسم المجلد/الملف (Excel)",
                                      prefixIcon:
                                      const Icon(Icons.insert_drive_file),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'هذا الحقل مطلوب'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _documentCtrl,
                                    decoration: InputDecoration(
                                      labelText: "لاحقة الإسم (Document)",
                                      prefixIcon:
                                      const Icon(Icons.description),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'هذا الحقل مطلوب'
                                        : null,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // الأزرار
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: isBusy
                                        ? null
                                        : () async {
                                      if (_formKey.currentState!
                                          .validate()) {
                                        await _onGenerate();
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
                                    onPressed: isBusy ? _onStop : null,
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
                                            : Colors.grey.shade300,
                                      ),
                                      foregroundColor:
                                      isBusy ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // بطاقات التقدم
                            if (state.excelProgress > 0)
                              _ProgressCard(
                                title: "جاري إنشاء ملف Excel...",
                                value: state.excelProgress,
                              ),
                            if (state.firestoreProgress > 0)
                              _ProgressCard(
                                title: "جاري رفع البيانات إلى Firestore...",
                                value: state.firestoreProgress,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final String url;
  const _BrandLogo({required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    // شبكة؟
    if (url.startsWith('http')) {
      // كسر كاش بسيط عند تغيّر الرابط/إعادة البناء بمفتاح جديد
      final bustedUrl =
          '$url${url.contains('?') ? '&' : '?'}ts=${DateTime.now().millisecondsSinceEpoch}';
      return FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder.png',
        image: bustedUrl,
        height: 150,
        fit: BoxFit.contain,
        imageErrorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, size: 70),
      );
    }

    // أصول
    return Image.asset(
      url,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.broken_image, size: 70),
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
