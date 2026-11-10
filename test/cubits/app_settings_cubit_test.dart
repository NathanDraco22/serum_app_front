import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_settings/app_settings_cubit.dart';
import 'package:serum_business/serum_business.dart';

class _FakeAppSettingsRepository extends AppSettingsRepository {
  _FakeAppSettingsRepository() : super(AppSettingsDataSource());

  AppSettingModel? _settings;

  @override
  AppSettingModel? get currentAppSettings => _settings;

  @override
  Future<AppSettingModel> getCurrentAppSettings() async {
    _settings ??= AppSettingModel(
      id: 'Default',
      currency: AppCurrency.nio,
      createdAt: 1,
    );
    return _settings!;
  }

  @override
  Future<AppSettingModel> updateAppSettings(
    String appSettingId,
    UpdateAppSetting body,
  ) async {
    final current = _settings ?? await getCurrentAppSettings();
    final updated = current.copyWith(
      useCost: body.useCost,
      usePrice2: body.usePrice2,
      allowEditPrice: body.allowEditPrice,
      currency: body.currency,
    );
    _settings = updated;
    return updated;
  }

  @override
  void clearCache() {
    _settings = null;
  }
}

void main() {
  late AppSettingsCubit cubit;

  setUp(() {
    cubit = AppSettingsCubit(_FakeAppSettingsRepository());
  });

  tearDown(() async {
    NumberFormatter.configureCurrencyResolver(null);
    await cubit.close();
  });

  test('expone NIO como fallback antes de cargar la configuración', () {
    expect(cubit.currency, AppCurrency.nio);
    expect(NumberFormatter.currency, AppCurrency.nio);
    expect(NumberFormatter.convertToMoneyLike(15050), 'C\$150.50');
  });

  test('el resolver usa la moneda cargada y se actualiza sin setters', () async {
    final repo = cubit.appSettingsRepository as _FakeAppSettingsRepository;

    await cubit.loadSettings();
    expect(cubit.currency, AppCurrency.nio);
    expect(NumberFormatter.convertToMoneyLike(15050), 'C\$150.50');

    await repo.updateAppSettings(
      'Default',
      const UpdateAppSetting(currency: AppCurrency.usd),
    );
    await cubit.loadSettings();

    expect(cubit.currency, AppCurrency.usd);
    expect(NumberFormatter.convertToMoneyLike(15050), 'US\$150.50');
  });

  test('updateSettings emite la nueva moneda y el formatter la refleja', () async {
    await cubit.loadSettings();

    final success = await cubit.updateSettings(
      const UpdateAppSetting(currency: AppCurrency.eur),
    );

    expect(success, isTrue);
    expect(cubit.currency, AppCurrency.eur);
    expect(NumberFormatter.convertToMoneyLike(15050), '€150.50');
  });

  test('reset limpia la configuración y vuelve al fallback', () async {
    await cubit.loadSettings();
    await cubit.updateSettings(
      const UpdateAppSetting(currency: AppCurrency.usd),
    );
    expect(NumberFormatter.currency, AppCurrency.usd);

    cubit.reset();

    expect(cubit.currency, AppCurrency.nio);
    expect(NumberFormatter.currency, AppCurrency.nio);
  });
}
