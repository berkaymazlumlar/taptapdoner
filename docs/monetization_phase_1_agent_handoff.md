# TapTap Döner — Monetization Faz 1 Agent Handoff

## 1. Amaç

Bu fazın amacı reklam, uygulama içi satın alma ve abonelik özelliklerinin daha sonra güvenli, ölçülebilir ve birbirinden ayrıştırılmış biçimde eklenebilmesi için ortak monetization temelini kurmaktır.

Bu fazda kullanılacak servisler:

- Satın alma ve abonelik hakları: RevenueCat (`purchases_flutter`)
- Analytics: Firebase Analytics
- Uzaktan ayar ve deney konfigürasyonu: Firebase Remote Config
- Reklam SDK'sı ve izin yönetimi: Google Mobile Ads + UMP
- Normal oyun kaydı: mevcut `SaveRepository` / `SharedPreferencesSaveRepository`

Bu doküman başka bir agente doğrudan uygulama görevi olarak verilebilir. Agent mevcut kirli worktree'deki kullanıcı değişikliklerini korumalı, ilgisiz dosyaları değiştirmemeli ve monetization kodunu mevcut oyun ekonomisinden ayrıştırmalıdır.

## 2. Kesinleşmiş ürün kararları

### Kapsamda

- Monetization servis mimarisi
- RevenueCat SDK kurulumu ve entitlement okuma altyapısı
- Firebase Analytics kurulumu ve event sözleşmesi
- Firebase Remote Config kurulumu ve yerel varsayılanlar
- UMP consent akışı ve reklam isteği uygunluğu
- Test edilebilir fake/no-op implementasyonlar
- Gerekli Android/iOS yapılandırma noktaları
- Restore/sync için temel API yüzeyi
- Monetization bootstrap akışı ve hata toleransı

### Kapsam dışında

- Sezon bileti
- Kozmetik IAP
- Gerçek paywall ekranı
- Gerçek ürün satın alma butonları
- Ürün ödüllerinin oyuncuya teslim edilmesi
- Gerçek rewarded reklam gösterimi
- Interstitial reklam gösterimi
- Subscription ekranı
- Oyun ekonomisine ücretli boost uygulamak
- Sandık satışı
- Kendi backend'ini kurmak
- Mevcut oyun denge değerlerini değiştirmek

Faz 1'in sonunda uygulama ürün satmamalı ve reklam göstermemelidir. Sadece sonraki fazların kullanacağı güvenli altyapı hazır olmalıdır.

## 3. Dış sistem önkoşulları

Repo Android tarafında `com.berkaymazlumlar.taptapdoner` application ID'sini kullanıyor.

Proje sahibinden alınması gerekenler:

- Nihai Android application ID
- Nihai iOS bundle ID
- Firebase Android `google-services.json`
- Firebase iOS `GoogleService-Info.plist`
- RevenueCat Android public SDK key
- RevenueCat iOS public SDK key
- AdMob Android app ID
- AdMob iOS app ID
- AdMob panelinde yayınlanmış privacy/consent message

Bu değerler mevcut değilse:

1. Agent dış panel veya production kimliği uydurmamalı.
2. Kod tarafını compile-safe no-op/fake servislerle tamamlamalı.
3. Eksik dosya ve değerleri sonuç raporunda açıkça listelemeli.
4. Gerçek anahtarları source control'e gömmemeli.

RevenueCat public SDK key bir istemci anahtarı olsa da platforma göre build-time konfigürasyondan okunmalıdır. Secret/admin API key hiçbir koşulda mobil uygulamaya eklenmemelidir.

## 4. Rezerve ürün ve entitlement kimlikleri

Faz 1'de mağaza ürünleri oluşturulmayacak; ancak kod genelinde kullanılacak sabit kimlikler tek yerde tanımlanmalıdır.

Ürün kimlikleri:

```text
starter_pack
boost_pack_small
boost_pack_large
remove_forced_ads
doner_club_monthly
```

RevenueCat entitlement kimlikleri:

```text
starter_pack_owned
forced_ads_removed
doner_club
```

RevenueCat offering kimliği:

```text
default
```

Bu string'ler UI, controller veya ekonomi kodunda tekrarlanmamalı; merkezi bir catalog/constants sınıfında tutulmalıdır.

## 5. Önerilen klasör yapısı

Mevcut yapıyla uyumlu olacak şekilde aşağıdakine yakın bir düzen kullanılmalıdır. Agent daha iyi bir isimlendirme seçebilir ancak sorumluluk sınırlarını korumalıdır.

```text
lib/
  services/
    monetization/
      monetization_bootstrap.dart
      monetization_config.dart
      monetization_product_catalog.dart
      monetization_analytics.dart
      firebase_monetization_analytics.dart
      remote_monetization_config.dart
      firebase_remote_monetization_config.dart
      entitlement_service.dart
      revenue_cat_entitlement_service.dart
      entitlement_snapshot.dart
      purchase_ledger.dart
      ad_consent_service.dart
      ump_ad_consent_service.dart
      no_op_*.dart
```

Dosyaların birebir bu kadar parçalı olması zorunlu değildir. Ancak aşağıdaki sınırlar zorunludur:

- `GameController` doğrudan Firebase, RevenueCat veya Google Mobile Ads import etmemeli.
- Domain/economy katmanı SDK sınıflarını bilmemeli.
- UI kodu RevenueCat `CustomerInfo` veya Firebase sınıflarını doğrudan kullanmamalı.
- Platform SDK'ları servis adaptörlerinin arkasında kalmalı.
- Testler fake implementasyon enjekte edebilmeli.

## 6. Veri sahipliği kuralları

### RevenueCat'in authoritative olduğu alanlar

- `starter_pack_owned`
- `forced_ads_removed`
- `doner_club` aktifliği
- Abonelik sona erme/yenilenme bilgisi
- Restore sonrası kalıcı satın alma hakları

### Yerel oyunun authoritative olduğu alanlar

- Para
- Prestige ilerlemesi
- Upgrade seviyeleri
- Şubeler
- Sandık envanteri
- Görevler
- Normal oyun istatistikleri

### Yerelde cache edilebilen fakat authoritative olmayan alanlar

- Son entitlement snapshot'ı
- Son başarılı RevenueCat sync zamanı
- Son bilinen abonelik sona erme zamanı
- Son Remote Config değerleri
- Consent durumu

RevenueCat hakları doğrudan `GameState` içine kalıcı gerçek olarak yazılmamalıdır. Gerekirse yalnızca hızlı/offline UI için ayrı bir cache modeli kullanılmalı ve RevenueCat senkronizasyonunda yenilenmelidir.

Consumable ürün ödüllerinin ileride iki kez verilmesini önlemek için bir `PurchaseLedger` arayüzü hazırlanmalıdır. Faz 1'de gerçek ödül teslimi yoktur; sadece aşağıdaki yetenekler tanımlanmalıdır:

```dart
abstract interface class PurchaseLedger {
  Future<bool> hasProcessed(String transactionId);
  Future<void> markProcessed(String transactionId);
}
```

Bu yerel ledger tek başına güvenlik garantisi olarak sunulmamalıdır. Gelecek fazda consumable teslimi tasarlanırken RevenueCat transaction bilgisi ve gerekirse backend/webhook stratejisi ayrıca ele alınacaktır.

## 7. Entitlement modeli

SDK'dan bağımsız, immutable bir snapshot modeli oluşturulmalıdır. En az aşağıdaki alanları içermelidir:

```text
isConfigured
isCustomerInfoAvailable
starterPackOwned
forcedAdsRemoved
donerClubActive
donerClubExpirationUtc
appUserId
lastSyncedAtUtc
```

Beklenen davranış:

- RevenueCat hazır değilse güvenli varsayılan tüm ücretli hakların `false` olmasıdır.
- Daha önce doğrulanmış ve süresi henüz dolmamış bir abonelik cache'i varsa kısa süreli offline tolerans uygulanabilir; bu tolerans ayrı bir config değeri olmalıdır.
- Yeni bir `CustomerInfo` geldiğinde snapshot güncellenmeli ve dinleyicilere bildirilmelidir.
- Entitlement mapping tek bir yerde yapılmalıdır.
- UI ve controller yalnızca bu snapshot modelini görmelidir.

`EntitlementService` en az şu yüzeyi sağlamalıdır:

```dart
abstract interface class EntitlementService {
  ValueListenable<EntitlementSnapshot> get snapshotListenable;
  Future<void> initialize({String? appUserId});
  Future<void> refresh();
  Future<void> restorePurchases();
  Future<void> logIn(String appUserId);
  Future<void> logOut();
}
```

Uygulamada henüz hesap sistemi olmadığı için ilk kurulum RevenueCat anonymous App User ID ile çalışabilir. Ancak servis ileride stabil bir kullanıcı ID'sine geçişi desteklemelidir. Cross-device entitlement beklentisinin gerçek bir hesap sistemi olmadan sınırlı olduğu dokümante edilmelidir.

## 8. Monetization Remote Config sözleşmesi

Tüm değerlerin uygulama içinde güvenli varsayılanı bulunmalıdır. Remote Config erişilemezse oyun bu varsayılanlarla açılmalıdır.

Faz 1'de tanımlanacak anahtarlar:

```text
monetization_enabled = false
rewarded_ads_enabled = false
interstitial_ads_enabled = false
iap_enabled = false
subscription_enabled = false

rewarded_global_daily_cap = 6
rewarded_income_boost_daily_cap = 3
rewarded_income_boost_cooldown_minutes = 60
rewarded_income_boost_duration_minutes = 10
rewarded_income_boost_multiplier = 2.0

interstitial_daily_cap = 2
interstitial_min_interval_minutes = 15
interstitial_first_session_enabled = false
interstitial_first_session_delay_minutes = 15

subscription_offline_grace_hours = 24
```

Kurallar:

- Production'da yeni monetization özelliği Remote Config flag'i açılmadan etkin olmamalı.
- Sayısal değerler makul min/max aralıklarına clamp edilmelidir.
- Bozuk veya eksik Remote Config değeri uygulamayı çökertmemelidir.
- Fetch/activate için timeout bulunmalıdır.
- Development/test ortamında minimum fetch interval makul biçimde azaltılabilir; production varsayılanı agresif olmamalıdır.
- Remote Config fetch işlemi oyun açılışını süresiz bloke etmemelidir.

Remote config değerlerini kullanan immutable bir `MonetizationConfigSnapshot` modeli ve bunu sağlayan test edilebilir bir servis arayüzü oluşturulmalıdır.

## 9. Analytics event sözleşmesi

Analytics çağrıları merkezi bir servis üzerinden yapılmalıdır. Özellik kodu doğrudan `FirebaseAnalytics.instance.logEvent` çağırmamalıdır.

Event isimleri:

```text
monetization_bootstrap_completed
monetization_bootstrap_failed
consent_flow_started
consent_flow_completed
consent_flow_failed
ad_offer_shown
ad_started
ad_completed
ad_reward_granted
ad_unavailable
paywall_viewed
purchase_started
purchase_completed
purchase_failed
purchase_restored
subscription_started
subscription_expired
```

Ortak parametreler:

```text
placement
product_id
entitlement_id
platform
locale
shop_level
prestige_count
result
error_code
```

Kurallar:

- Para miktarı, dev oyun sayıları veya kişisel veri event parametresi olarak gönderilmemeli.
- Hata mesajının tamamı analytics'e gönderilmemeli; normalize edilmiş `error_code` kullanılmalı.
- Event isimleri ve parametre anahtarları constants olarak tutulmalı.
- Testlerde event adı ve parametreleri doğrulanabilmeli.
- Analytics kapalı veya initialize edilememişse no-op davranmalı.
- Consent tercihi analytics kullanımını kapsamıyorsa collection buna uygun şekilde kapatılmalıdır.

Önerilen user property'ler:

```text
locale
highest_shop_level_bucket
prestige_count_bucket
is_payer
subscription_status
```

Yüksek cardinality oluşturacak ham değerler yerine bucket kullanılmalıdır.

## 10. UMP consent servisi

`AdConsentService` SDK'dan bağımsız olmalıdır. En az aşağıdaki durumları sunmalıdır:

```text
unknown
notRequired
required
obtained
unavailable
failed
```

Yüzey önerisi:

```dart
abstract interface class AdConsentService {
  ValueListenable<AdConsentSnapshot> get snapshotListenable;
  Future<void> gatherConsentIfRequired();
  Future<void> showPrivacyOptions();
  bool get canRequestAds;
}
```

Kurallar:

- UMP consent sonucu alınmadan reklam isteği yapılmamalı.
- `canRequestAds` false iken Mobile Ads reklam yükleme akışı başlamamalı.
- Consent form hata verirse oyun açılmaya devam etmeli.
- UMP privacy options gerekiyorsa gelecekte Ayarlar ekranında gösterilebilmesi için servis metodu hazır olmalı.
- Debug geography/test device ayarları yalnızca debug build'de kullanılmalı.
- Test reklam ID'leri dışında production olmayan build'de gerçek reklam ID'si kullanılmamalı.
- Faz 1'de consent akışı hazır olabilir ancak reklam yüklenmez veya gösterilmez.

iOS ATT gösterimi bu fazda zorunlu UI kapsamı değildir. Bununla birlikte consent servisi ve bootstrap sırası, ileride GDPR/UMP sonucundan sonra ATT istenmesine engel olmayacak şekilde tasarlanmalıdır.

## 11. Bootstrap sırası ve hata toleransı

Önerilen başlangıç sırası:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Firebase initialize
3. Analytics adapter initialize
4. Remote Config defaults yükle
5. Remote Config fetch/activate işlemini timeout ile başlat
6. RevenueCat'i platform public SDK key ile configure et
7. İlk entitlement snapshot'ını çek ve listener bağla
8. UMP consent bilgisini güncelle ve gerekiyorsa formu göster
9. Yalnızca `canRequestAds == true` olduğunda Mobile Ads SDK init etmeye izin ver
10. Sonucu tek bir bootstrap snapshot/log ile raporla
11. Mevcut oyun initialization akışına devam et

Bootstrap fail-soft olmalıdır:

- Firebase hatası oyunu açılmaz hale getirmemeli.
- Remote Config hatasında defaults kullanılmalı.
- RevenueCat hatasında ücretli haklar güvenli false/no-op durumunda kalmalı.
- UMP hatasında reklam isteği yapılmamalı fakat oyun açılmalı.
- Her dış servis için makul timeout kullanılmalı.
- Aynı bootstrap metodu yanlışlıkla iki kez çağrılsa bile SDK'lar iki kez configure edilmemeli.
- Debug log'larında secret veya tam receipt/token bulunmamalı.

Mevcut `TapTapDonerApp` ve `GameController` testlerinin kolay enjekte edilebilir yapısı korunmalıdır. Testler gerçek Firebase/RevenueCat initialize etmeye zorlanmamalıdır.

## 12. Platform konfigürasyonu

### Android

- Nihai application ID gelmeden Firebase/AdMob production kaydı tamamlanmamalı.
- Gerekli Google services Gradle plugin yapılandırması resmi FlutterFire kurulumuna uygun yapılmalı.
- AdMob app ID manifest meta-data değeri build konfigürasyonundan gelmeli veya production değeri dış önkoşul olarak bırakılmalı.
- RevenueCat ve diğer paketlerin minimum SDK gereksinimleri kontrol edilmeli; gereksiz yere minSdk yükseltilmemeli.
- Release signing mevcut kapsam dışıdır; ancak debug signing'in release'te kullanıldığı sonuç raporunda hatırlatılmalıdır.

### iOS

- Nihai bundle ID gelmeden Firebase/AdMob production kaydı tamamlanmamalı.
- `GoogleService-Info.plist` yalnızca doğru target'a eklenmeli.
- AdMob app ID `Info.plist` içine resmi anahtar ile eklenmeli.
- RevenueCat minimum iOS gereksinimi ile mevcut deployment target uyumu kontrol edilmeli.
- StoreKit ürünleri bu fazda oluşturulmamalı.
- ATT kullanım açıklaması/prompt'u, gerçek ATT akışı eklenene kadar yanlış veya erken gösterilmemeli.

### Desteklenmeyen platformlar

Proje web, Windows, macOS ve Linux klasörleri içeriyor. Monetization servisleri bu platformlarda uygulamayı kırmamalıdır.

- Android/iOS dışında no-op implementasyon kullanılmalı.
- Unsupported platform'da RevenueCat/AdMob initialize etmeye çalışılmamalı.
- Mevcut web ve masaüstü test/build davranışı mümkün olduğunca korunmalı.

## 13. Bağımlılıklar

Güncel ve birbiriyle uyumlu stable sürümler çözülerek aşağıdaki paketler eklenmelidir:

```text
purchases_flutter
firebase_core
firebase_analytics
firebase_remote_config
google_mobile_ads
```

Kurallar:

- Versiyonlar tahmin edilmemeli; uygulama sırasında pub.dev ve resmi dokümantasyondaki güncel stable sürüm doğrulanmalı.
- Transitive native dependency çakışmaları kontrol edilmeli.
- Kullanılmayan ek paketler eklenmemeli.
- RevenueCat yerine ayrıca `in_app_purchase` eklenmemeli.

## 14. Test planı

En az aşağıdaki unit/widget testleri eklenmelidir:

### Monetization config

- Yerel defaults doğru yüklenir.
- Eksik Remote Config değeri default'a düşer.
- Negatif veya aşırı değerler clamp edilir.
- Feature flag'ler varsayılan olarak kapalıdır.

### Entitlement mapping

- Boş CustomerInfo tüm hakları false üretir.
- Her entitlement bağımsız ve doğru map edilir.
- Süresi geçmiş abonelik aktif sayılmaz.
- Listener güncellemesi snapshot'ı değiştirir.
- RevenueCat hatası mevcut güvenli snapshot'ı bozmaz.

### Consent

- `canRequestAds == false` iken reklam SDK init callback'i çağrılmaz.
- Consent obtained olduğunda reklam init'e izin verilir.
- Consent form hatası bootstrap'ı çökertmez.
- Privacy options metodu fake ile doğrulanabilir.

### Bootstrap

- Bütün servisler başarılı olduğunda ready sonucu verir.
- Remote Config başarısızken defaults ile devam eder.
- RevenueCat başarısızken oyun açılır.
- Consent başarısızken reklamlar kapalı kalır.
- Aynı anda/arka arkaya iki initialize çağrısı idempotent davranır.
- Unsupported platform no-op servislerle tamamlanır.

### Analytics

- Event isimleri sözleşmeyle aynıdır.
- PII veya raw error message gönderilmez.
- No-op analytics exception üretmez.
- Parametreler test fake'i üzerinden yakalanabilir.

Mevcut testler değiştirilmeden veya yalnızca zorunlu injection uyarlamalarıyla geçmeye devam etmelidir.

## 15. Kabul kriterleri

Faz 1 tamamlanmış sayılmak için:

- [ ] RevenueCat, Firebase Analytics, Firebase Remote Config ve Google Mobile Ads bağımlılıkları eklenmiş olmalı.
- [ ] SDK'lar domain ve UI katmanından adapter arkasına alınmış olmalı.
- [ ] RevenueCat CustomerInfo, SDK bağımsız entitlement snapshot'ına çevrilebilmeli.
- [ ] Restore, refresh, login ve logout için servis API'si bulunmalı.
- [ ] Anonymous RevenueCat başlangıcı desteklenmeli.
- [ ] Remote Config yerel defaults ve clamp kuralları uygulanmış olmalı.
- [ ] Production monetization feature flag'leri varsayılan olarak kapalı olmalı.
- [ ] Analytics event sözleşmesi ve test edilebilir adapter bulunmalı.
- [ ] UMP consent sonucu olmadan reklam isteği yapılamamalı.
- [ ] Dış servis hataları oyunun açılmasını engellememeli.
- [ ] Unsupported platformlar no-op davranmalı.
- [ ] Hiçbir gerçek reklam gösterilmemeli.
- [ ] Hiçbir gerçek ürün satın alma akışı açılmamalı.
- [ ] Secret/admin anahtarı repoya eklenmemeli.
- [ ] Yeni unit testler geçmeli.
- [ ] Mevcut `flutter test` paketi geçmeli.
- [ ] `flutter analyze` yeni hata üretmemeli.
- [ ] Değiştirilen Dart dosyaları formatlanmış olmalı.
- [ ] Eksik external console/config adımları sonuç raporunda listelenmeli.

## 16. Doğrulama komutları

Agent çalışma sonunda en az şunları çalıştırmalıdır:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Platform config dosyaları ve geçerli application/bundle ID sağlanmışsa ayrıca:

```powershell
flutter build apk --debug
```

iOS build yalnızca uygun macOS/Xcode ortamında doğrulanabilir. Çalıştırılamayan platform doğrulamaları sonuç raporunda açıkça belirtilmelidir.

## 17. Agent teslim raporu formatı

Agent tamamlandığında şu başlıklarla kısa bir rapor vermelidir:

1. Eklenen mimari ve servisler
2. RevenueCat entegrasyon durumu
3. Firebase entegrasyon durumu
4. UMP/AdMob consent durumu
5. Eklenen testler
6. Çalıştırılan doğrulamalar ve sonuçları
7. Eksik dış konfigürasyonlar
8. Faz 2 için hazır olan API yüzeyleri
9. Bilinen riskler veya takip işleri

## 18. Faz 2'ye geçiş kapısı

Faz 2'de ilk gerçek özellik offline kazancı rewarded reklamla 2x alma olacaktır. Faz 2 başlamadan önce şu şartlar sağlanmalıdır:

- Nihai Android/iOS uygulama kimlikleri belirlenmiş olmalı.
- Firebase config dosyaları doğru target'lara eklenmiş olmalı.
- RevenueCat uygulamaları ve entitlement'ları panelde oluşturulmuş olmalı.
- AdMob uygulamaları oluşturulmuş olmalı.
- UMP privacy message yayınlanmış olmalı.
- Test cihazında consent akışı doğrulanmış olmalı.
- Remote Config üzerinden `rewarded_ads_enabled` kontrollü biçimde açılabilir olmalı.
- Analytics'te bootstrap ve consent event'leri görülebilmeli.

Bu kapı sağlanmadan gerçek rewarded ad unit ID'leriyle geliştirme yapılmamalıdır.
