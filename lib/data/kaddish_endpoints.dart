import '../tenant/tenant_runtime.dart';

/// Kaddish board URLs for the active tenant.
String get kaddishHost => TenantRuntime.instance.config.kaddishHost;

String get kaddishBoardApi => TenantRuntime.instance.config.kaddishBoardApi;

String get kaddishBoardFullApi => TenantRuntime.instance.config.kaddishBoardFullApi;

String get kaddishBoardPersonApi =>
    TenantRuntime.instance.config.kaddishBoardPersonApi;

String get kaddishPhotoBase => TenantRuntime.instance.config.kaddishPhotoBase;

String get kaddishPublicBoardUrl => TenantRuntime.instance.config.kaddishBoardUrl;
