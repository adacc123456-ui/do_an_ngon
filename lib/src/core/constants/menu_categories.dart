class MenuCategories {
  MenuCategories._();

  static const String rice = 'com';
  static const String noodles = 'bun-pho-chao';
  static const String seafood = 'hai-san';
  static const String coffee = 'coffee';
  static const String snacks = 'do-an-nhe';
  static const String fastFood = 'do-an-nhanh';

  static const Map<String, String> _displayNames = {
    rice: 'Cơm',
    noodles: 'Bún - Phở - Cháo',
    seafood: 'Hải sản',
    coffee: 'Coffee',
    snacks: 'Đồ ăn nhẹ',
    fastFood: 'Đồ ăn nhanh',
  };

  static const Map<String, String> _icons = {
    rice: 'assets/svgs/icon_rice.svg',
    noodles: 'assets/svgs/icon_noodles.svg',
    seafood: 'assets/svgs/icon_seafood.svg',
    coffee: 'assets/svgs/icon_coffee.svg',
    snacks: 'assets/svgs/icon_snacks.svg',
    fastFood: 'assets/svgs/icon_fast_food.svg',
  };

  static String normalizeKey(String? rawKey) {
    return rawKey?.trim().toLowerCase() ?? '';
  }

  static String resolveName(String key, {String? fallback}) {
    final normalized = normalizeKey(key);
    return _displayNames[normalized] ?? fallback ?? 'Danh mục';
  }

  static String? resolveIcon(String key) {
    final normalized = normalizeKey(key);
    return _icons[normalized];
  }
}

