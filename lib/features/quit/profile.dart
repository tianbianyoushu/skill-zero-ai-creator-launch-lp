import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/shared_prefs_storage.dart';

class QuitProfile {
  final DateTime? quitDate;
  final int cigarettesPerDay;
  final int cigsPerPack;
  final int packPrice; // price per pack in selected currency
  final String countryCode;
  final String currencyCode;

  const QuitProfile({
    this.quitDate,
    this.cigarettesPerDay = 20,
    this.cigsPerPack = 20,
    this.packPrice = 600,
    this.countryCode = 'JP',
    this.currencyCode = 'JPY',
  });

  QuitProfile copyWith({
    DateTime? quitDate,
    int? cigarettesPerDay,
    int? cigsPerPack,
    int? packPrice,
    String? countryCode,
    String? currencyCode,
  }) =>
      QuitProfile(
        quitDate: quitDate ?? this.quitDate,
        cigarettesPerDay: cigarettesPerDay ?? this.cigarettesPerDay,
        cigsPerPack: cigsPerPack ?? this.cigsPerPack,
        packPrice: packPrice ?? this.packPrice,
        countryCode: countryCode ?? this.countryCode,
        currencyCode: currencyCode ?? this.currencyCode,
      );

  bool get isOnboarded => quitDate != null;

  Duration elapsed(DateTime now) {
    if (quitDate == null) return Duration.zero;
    return now.difference(quitDate!).isNegative
        ? Duration.zero
        : now.difference(quitDate!);
  }

  double pricePerCig() => packPrice / cigsPerPack;

  int cigarettesAvoided(DateTime now) {
    if (quitDate == null) return 0;
    final days = elapsed(now).inMinutes / (60 * 24);
    return (days * cigarettesPerDay).floor();
  }

  num moneySaved(DateTime now) {
    final avoided = cigarettesAvoided(now);
    return avoided * pricePerCig();
  }

  Map<String, dynamic> toMap() => {
        'quitDate': quitDate?.toIso8601String(),
        'cigarettesPerDay': cigarettesPerDay,
        'cigsPerPack': cigsPerPack,
        'packPrice': packPrice,
        'countryCode': countryCode,
        'currencyCode': currencyCode,
      };

  factory QuitProfile.fromMap(Map<String, dynamic> map) => QuitProfile(
        quitDate:
            map['quitDate'] != null ? DateTime.parse(map['quitDate']) : null,
        cigarettesPerDay: map['cigarettesPerDay'] ?? 20,
        cigsPerPack: map['cigsPerPack'] ?? 20,
        packPrice: map['packPrice'] ?? 600,
        countryCode: map['countryCode'] ?? 'JP',
        currencyCode: map['currencyCode'] ?? 'JPY',
      );
}

class ProfileController extends StateNotifier<QuitProfile> {
  ProfileController() : super(const QuitProfile()) {
    _load();
  }

  final _storage = SharedPrefsStorage();

  Future<void> _load() async {
    final loaded = await _storage.loadProfile();
    if (loaded != null) state = loaded;
  }

  void setProfile({
    required DateTime quitDate,
    required int cigarettesPerDay,
    required int cigsPerPack,
    required int packPrice,
    required String countryCode,
    required String currencyCode,
  }) {
    state = QuitProfile(
      quitDate: quitDate,
      cigarettesPerDay: cigarettesPerDay,
      cigsPerPack: cigsPerPack,
      packPrice: packPrice,
      countryCode: countryCode,
      currencyCode: currencyCode,
    );
    _storage.saveProfile(state);
  }

  void updateCountry(String code) {
    state = state.copyWith(countryCode: code);
    _storage.saveProfile(state);
  }

  void updateCurrency(String code) {
    state = state.copyWith(currencyCode: code);
    _storage.saveProfile(state);
  }

  void reset() {
    state = const QuitProfile();
    _storage.saveProfile(state);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileController, QuitProfile>((ref) {
  return ProfileController();
});
