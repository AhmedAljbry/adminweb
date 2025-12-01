
// ─────────────────────────── STATE ───────────────────────────
import 'package:equatable/equatable.dart';
import 'package:triing/Core/utils/enum.dart';
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

class BatchResultEntity extends Equatable {
  final int requestedCount;
  final int uploadedToFirestore;
  final String? savedExcelPath;
  final bool stopped;

  const BatchResultEntity({
    required this.requestedCount,
    required this.uploadedToFirestore,
    this.savedExcelPath,
    this.stopped = false,
  });

  BatchResultEntity copyWith({
    int? requestedCount,
    int? uploadedToFirestore,
    String? savedExcelPath,
    bool? stopped,
  }) {
    return BatchResultEntity(
      requestedCount: requestedCount ?? this.requestedCount,
      uploadedToFirestore: uploadedToFirestore ?? this.uploadedToFirestore,
      savedExcelPath: savedExcelPath ?? this.savedExcelPath,
      stopped: stopped ?? this.stopped,
    );
  }

  @override
  List<Object?> get props => [
    requestedCount,
    uploadedToFirestore,
    savedExcelPath,
    stopped
  ];
}

class GenCodeState extends Equatable {
  final RequestState batchState;
  final String message;
  final double firestoreProgress;
  final double excelProgress;
  final bool isRunning;
  final bool stopRequested;
  final bool isOnline;
  final int selectedIndex;
  final BatchResultEntity? result;
  final IdInfo? lastTarget;

  const GenCodeState({
    this.selectedIndex = 0,
    this.batchState = RequestState.loading,
    this.message = '',
    this.firestoreProgress = 0.0,
    this.excelProgress = 0.0,
    this.isRunning = false,
    this.stopRequested = false,
    this.isOnline = true,
    this.result,
    this.lastTarget,
  });

  GenCodeState copyWith({
    int? selectedIndex,
    RequestState? batchState,
    String? message,
    double? firestoreProgress,
    double? excelProgress,
    bool? isRunning,
    bool? stopRequested,
    bool? isOnline,
    BatchResultEntity? result,
    IdInfo? lastTarget,
  }) {
    return GenCodeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      batchState: batchState ?? this.batchState,
      message: message ?? this.message,
      firestoreProgress: firestoreProgress ?? this.firestoreProgress,
      excelProgress: excelProgress ?? this.excelProgress,
      isRunning: isRunning ?? this.isRunning,
      stopRequested: stopRequested ?? this.stopRequested,
      isOnline: isOnline ?? this.isOnline,
      result: result ?? this.result,
      lastTarget: lastTarget ?? this.lastTarget,
    );
  }

  @override
  List<Object?> get props => [
    selectedIndex,
    batchState,
    message,
    firestoreProgress,
    excelProgress,
    isRunning,
    stopRequested,
    isOnline,
    result,
    lastTarget,
  ];
}