// lib/genertcode/presentation/manager/gen_code_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:triing/Core/AppNotifications/AppNotifications.dart';
import 'package:triing/Core/utils/enum.dart';

import 'package:triing/genertcode/data/data_sources/Genert_code_data_soures.dart';
import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

import 'package:triing/genertcode/presentation/manager/gen_code_event.dart';
import 'package:triing/genertcode/presentation/manager/gen_code_state.dart';

class GenCodeBloc extends Bloc<BaseGenCodeEvent, GenCodeState> {
  GenCodeBloc() : super(const GenCodeState()) {
    // مراقبة الشبكة
    on<StartConnectivityWatch>(_onStartConnectivityWatch);
    on<ConnectivityChanged>(_onConnectivityChanged);

    // البدء
    on<StartBatchRequested>(_onStartBatchRequested);

    // (اختياري) الاستئناف – الآن لا نستخدمه، لكن نترك الحدث موجود
    on<TryResumeFromDisk>(_onTryResumeFromDisk);

    // التحكّم
    on<StopBatchEvent>(_onStop);
    on<ResetBatchEvent>(_onReset);

    // التقدّم والنتائج
    on<GenCodeProgressUpdated>(_onProgressUpdated);
    on<GenCodeDoneOk>(_onDoneOk);
    on<GenCodeDoneError>(_onDoneError);

    // تبويبات
    on<ItemTappedEvent>(_onItemTapped);
  }

  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // ───────────────── مراقبة الشبكة ─────────────────
  Future<void> _onStartConnectivityWatch(
      StartConnectivityWatch event,
      Emitter<GenCodeState> emit,
      ) async {
    try {
      final results = await Connectivity().checkConnectivity();
      emit(state.copyWith(isOnline: _anyOnline(results)));

      await _connSub?.cancel();
      _connSub = Connectivity().onConnectivityChanged.listen((results) {
        add(ConnectivityChanged(_anyOnline(results)));
      });
    } catch (_) {
      emit(state.copyWith(isOnline: true));
    }
  }

  void _onConnectivityChanged(
      ConnectivityChanged event,
      Emitter<GenCodeState> emit,
      ) {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  bool _anyOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
    r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  // ───────────────── البدء ─────────────────
  Future<void> _onStartBatchRequested(
      StartBatchRequested e,
      Emitter<GenCodeState> emit,
      ) async {
    if (state.isRunning) return;

    if (!state.isOnline) {
      emit(state.copyWith(
        batchState: RequestState.error,
        message: 'لا يوجد اتصال بالإنترنت',
      ));
      return;
    }

    if (e.count <= 0 ||
        e.collection.trim().isEmpty ||
        e.file.trim().isEmpty ||
        e.document.trim().isEmpty) {
      emit(state.copyWith(
        batchState: RequestState.error,
        message: 'جميع الحقول مطلوبة (وأدخل عددًا صحيحًا > 0)',
      ));
      return;
    }

    final target = IdInfo(
      idCollection: e.collection.trim(),
      idFile: e.file.trim(),
      idDocument: e.document.trim(),
    );

    emit(state.copyWith(
      batchState: RequestState.loading,
      message: '',
      firestoreProgress: 0.0,
      excelProgress: 0.0,
      isRunning: true,
      stopRequested: false,
      result: null,
      lastTarget: target,
    ));

    await AppNotifications.showSimple(
      id: AppNotifications.idGeneral,
      title: 'بدء العملية',
      body: 'جاري إنشاء الملف ورفع البيانات…',
    );

    try {
      // 1) توليد الـ IDs في الواجهة
      final now = DateTime.now();
      final ids = List<IdModel>.generate(e.count, (_) {
        final id = _uuid.v4().replaceAll('-', '').substring(0, 12);
        return IdModel(id: id, timestamp: now);
      });

      // 2) حفظ CSV في Download/code
      final savedPath = await _saveIdsCsvToDownloads(
        ids: ids,
        target: target,
      );

      // نحدّث تقدّم الإكسل إلى 100%
      add(const GenCodeProgressUpdated(excel: 1.0));

      // 3) رفع Firestore
      final ds = GetIt.I<BaseGenCodeDataSource>();
      double fs = 0.0;

      final uploaded = await ds.saveIdsToFirestore(
        ids: ids,
        target: target,
        onProgress: (p) async {
          fs = p;
          add(GenCodeProgressUpdated(firestore: p));
        },
        isStopped: () => state.stopRequested,
      );

      // 4) بناء الرسالة (تحتوي مسار الحفظ)
      final body = savedPath == null
          ? 'تم إنشاء الملف ورفع البيانات ✅\n(تعذر تحديد مسار الملف)'
          : 'تم إنشاء الملف ورفع البيانات ✅\n'
          'مسار الحفظ:\n$savedPath';

      await AppNotifications.showSuccessDone(
        title: 'تمت العملية',
        body: body,
      );

      // نرسل نتيجة النجاح إلى الـ UI
      add(GenCodeDoneOk(
        uploaded: uploaded,
        requested: e.count,
        path: savedPath,
      ));
    } catch (e) {
      final err = e.toString();
      await AppNotifications.showErrorDone(err);
      add(GenCodeDoneError(message: err));
    }
  }

  // ───────────────── حفظ CSV في Download/code ─────────────────
  Future<String?> _saveIdsCsvToDownloads({
    required List<IdModel> ids,
    required IdInfo target,
  }) async {
    try {
      // 1) بناء CSV
      final buffer = StringBuffer();
      buffer.writeln('id,timestamp,collection,file,document');
      for (final e in ids) {
        buffer.writeln(
          '${e.id},'
              '${e.timestamp.toIso8601String()},'
              '${target.idCollection},'
              '${target.idFile},'
              '${target.idDocument}',
        );
      }

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

      String? fullPath;

      if (Platform.isAndroid) {
        // 👈 مسار أندرويد: /storage/emulated/0/Download/code
        const base = '/storage/emulated/0/Download';
        final dir = Directory('$base/code');

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final baseName =
        (target.idFile.isEmpty ? 'ids' : target.idFile).trim();
        final sanitized = baseName.replaceAll(
          RegExp(r'[\\/:*?"<>|]'),
          '_',
        );
        final fileName =
            '${sanitized}_${DateTime.now().millisecondsSinceEpoch}.csv';

        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        fullPath = file.path;
      } else {
        // باقي المنصات → نستخدم file_saver
        final baseName =
        (target.idFile.isEmpty ? 'ids' : target.idFile).trim();
        final sanitized = baseName.replaceAll(
          RegExp(r'[\\/:*?"<>|]'),
          '_',
        );
        final fileName =
            '${sanitized}_${DateTime.now().millisecondsSinceEpoch}';

        final savedPath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'csv',             // ✅ التصحيح
          mimeType: MimeType.csv,
        );
        fullPath = savedPath;
      }

      return fullPath;
    } catch (e) {
      // لو فشل الحفظ ما نكسر العملية
      return null;
    }
  }

  // ───────────────── الاستئناف (حاليًا لا شيء) ─────────────────
  Future<void> _onTryResumeFromDisk(
      TryResumeFromDisk e,
      Emitter<GenCodeState> emit,
      ) async {
    // حالياً لا يوجد استئناف – يمكنك لاحقاً قراءة آخر نتيجة من Firestore أو من ملف.
  }

  // ───────────────── تقدّم ونتائج ─────────────────
  void _onProgressUpdated(
      GenCodeProgressUpdated e,
      Emitter<GenCodeState> emit,
      ) {
    emit(state.copyWith(
      firestoreProgress: e.firestore ?? state.firestoreProgress,
      excelProgress: e.excel ?? state.excelProgress,
    ));
  }

  void _onDoneOk(
      GenCodeDoneOk e,
      Emitter<GenCodeState> emit,
      ) {
    final result = BatchResultEntity(
      requestedCount: e.requested ?? 0,
      uploadedToFirestore: e.uploaded,
      savedExcelPath: e.path,
      stopped: state.stopRequested,
    );

    emit(state.copyWith(
      batchState: RequestState.loaded,
      isRunning: false,
      result: result,
      message: 'تمت العملية بنجاح',
      firestoreProgress: 1.0,
      excelProgress: 1.0,
    ));
  }

  void _onDoneError(
      GenCodeDoneError e,
      Emitter<GenCodeState> emit,
      ) {
    emit(state.copyWith(
      batchState: RequestState.error,
      isRunning: false,
      message: e.message,
    ));
  }

  // ───────────────── تحكّم ─────────────────
  Future<void> _onStop(
      StopBatchEvent e,
      Emitter<GenCodeState> emit,
      ) async {
    emit(state.copyWith(stopRequested: true, isRunning: false));

    await AppNotifications.showSimple(
      id: AppNotifications.idGeneral,
      title: 'تم الإيقاف',
      body: 'تم إيقاف العملية من قبل المستخدم',
    );
  }

  Future<void> _onReset(
      ResetBatchEvent e,
      Emitter<GenCodeState> emit,
      ) async {
    emit(GenCodeState(
      selectedIndex: state.selectedIndex,
      isOnline: state.isOnline,
      batchState: RequestState.loading,
      message: '',
      firestoreProgress: 0.0,
      excelProgress: 0.0,
      isRunning: false,
      stopRequested: false,
      result: null,
    ));
  }

  // تبويبات
  void _onItemTapped(ItemTappedEvent e, Emitter<GenCodeState> emit) {
    emit(state.copyWith(selectedIndex: e.index));
  }

  @override
  Future<void> close() async {
    await _connSub?.cancel();
    return super.close();
  }
}
