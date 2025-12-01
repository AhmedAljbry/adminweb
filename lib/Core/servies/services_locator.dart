// lib/genertcode/di/gen_code_service_locator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

// Data / Repo / UseCase
import 'package:triing/genertcode/data/data_sources/Genert_code_data_soures.dart';
import 'package:triing/genertcode/data/repositories/GenCodeRepositoryImpl.dart';
import 'package:triing/genertcode/domain/repositories/Base_generate_code.dart';
import 'package:triing/genertcode/domain/use_cases/run_Batch_use_case.dart';

// Bloc (بدون Runner الآن)
import 'package:triing/genertcode/presentation/manager/gen_code_bloc.dart';

final sl = GetIt.instance;

class GenCodeServicesLocator {
  Future<void> init() async {
    print('🚀 بدء تسجيل خدمات GenCode ...');

    await _ensureFirebaseInitialized();
    await _registerGenCodeService();

    print(
      '🔎 checks: '
          'DataSource=${sl.isRegistered<BaseGenCodeDataSource>()}, '
          'Repo=${sl.isRegistered<BaseGenCodeRepository>()}, '
          'UseCase=${sl.isRegistered<RunBatchUseCase>()}, '
          'BlocFactory=${sl.isRegistered<GenCodeBloc>()}',
    );
    print('✅ كل الخدمات تم تسجيلها بنجاح');
  }

  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('ℹ️ Firebase غير مهيأ — جاري التهيئة...');
        await Firebase.initializeApp();
        print('✅ تم تهيئة Firebase');
      } else {
        print('✅ Firebase مهيأ مسبقًا');
      }
    } catch (e) {
      print('⚠️ فشل تهيئة Firebase: $e');
    }
  }

  Future<void> _registerGenCodeService() async {
    try {
      // DataSource
      _registerIfAbsent<BaseGenCodeDataSource>(
        name: 'BaseGenCodeDataSource',
        factory: () => GenertCodeDataSource(FirebaseFirestore.instance),
      );

      // Repository
      _registerIfAbsent<BaseGenCodeRepository>(
        name: 'BaseGenCodeRepository',
        factory: () => GenCodeRepositoryImpl(dataSource: sl()),
      );

      // UseCase (لو تحتاجه في أماكن أخرى)
      _registerIfAbsent<RunBatchUseCase>(
        name: 'RunBatchUseCase',
        factory: () => RunBatchUseCase(repository: sl()),
      );

      // Bloc (نسخة جديدة كل مرة، بدون Runner)
      _registerFactoryIfAbsent<GenCodeBloc>(
        name: 'GenCodeBloc',
        factory: () => GenCodeBloc(),
      );
    } catch (e, st) {
      print('❌ خطأ أثناء تسجيل الخدمات: $e');
      print(st);
    }
  }

  // Helpers
  void _registerIfAbsent<T extends Object>({
    required String name,
    required T Function() factory,
  }) {
    if (!sl.isRegistered<T>()) {
      sl.registerLazySingleton<T>(factory);
      print('📦 $name تم تسجيله');
    } else {
      print('↪️ $name مسجل مسبقًا — تم تخطيه');
    }
  }

  void _registerFactoryIfAbsent<T extends Object>({
    required String name,
    required T Function() factory,
  }) {
    if (!sl.isRegistered<T>()) {
      sl.registerFactory<T>(factory);
      print('📦 $name تم تسجيله (factory)');
    } else {
      print('↪️ $name (factory) مسجل مسبقًا — تم تخطيه');
    }
  }
}
