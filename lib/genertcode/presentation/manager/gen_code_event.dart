// ─────────────────────────── EVENTS ───────────────────────────
import 'package:equatable/equatable.dart';

sealed class BaseGenCodeEvent extends Equatable {
  const BaseGenCodeEvent();
  @override
  List<Object?> get props => [];
}

/// مراقبة الاتصال
class StartConnectivityWatch extends BaseGenCodeEvent {
  const StartConnectivityWatch();
}

class ConnectivityChanged extends BaseGenCodeEvent {
  final bool isOnline;
  const ConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

/// بدء العملية من الواجهة
class StartBatchRequested extends BaseGenCodeEvent {
  final int count;
  final String collection;
  final String file;
  final String document;

  const StartBatchRequested({
    required this.count,
    required this.collection,
    required this.file,
    required this.document,
  });

  @override
  List<Object?> get props => [count, collection, file, document];
}

/// محاولة استئناف من التخزين
class TryResumeFromDisk extends BaseGenCodeEvent {
  const TryResumeFromDisk();
}

/// إيقاف الخدمة/المهمة
class StopBatchEvent extends BaseGenCodeEvent {
  const StopBatchEvent();
}

/// إعادة ضبط الحالة
class ResetBatchEvent extends BaseGenCodeEvent {
  const ResetBatchEvent();
}

/// تقدّم
class GenCodeProgressUpdated extends BaseGenCodeEvent {
  final double? firestore; // 0..1
  final double? excel; // 0..1
  const GenCodeProgressUpdated({this.firestore, this.excel});

  @override
  List<Object?> get props => [firestore, excel];
}

/// اكتمال بنجاح
class GenCodeDoneOk extends BaseGenCodeEvent {
  final int uploaded;
  final int? requested;
  final String? path;

  const GenCodeDoneOk({
    required this.uploaded,
    this.requested,
    this.path,
  });

  @override
  List<Object?> get props => [uploaded, requested, path];
}

/// فشل
class GenCodeDoneError extends BaseGenCodeEvent {
  final String message;
  const GenCodeDoneError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// التنقّل بين التبويبات
class ItemTappedEvent extends BaseGenCodeEvent {
  final int index;
  const ItemTappedEvent(this.index);

  @override
  List<Object?> get props => [index];
}
