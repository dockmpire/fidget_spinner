/// Canonical product ID constants for all premium fidget toys.
/// These must exactly match the product IDs configured in App Store Connect.
class IAPProductIds {
  // Premium fidgets
  static const String waterGun = 'com.formfresh.fidgets.water_gun';

  // Future toys — define here before adding to App Store Connect:
  // static const String popIt   = 'com.formfresh.fidgets.pop_it';
  // static const String clicker = 'com.formfresh.fidgets.clicker';

  /// All product IDs — passed to the store when loading product details.
  static const Set<String> all = {
    waterGun,
  };

  /// Maps a fidget ID (from FidgetDefinition) to its product ID.
  static const Map<String, String> fidgetToProduct = {
    'water_gun': waterGun,
  };
}
