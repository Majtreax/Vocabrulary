// TRANSLITERATION AND TEXT NORMALIZATION UTILITY
class Transliterator {
  // CYRILLIC TO LATIN CHARACTER MAPPING
  static const Map<String, String> _cyrillicToLatin = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'e',
    'ж': 'zh',
    'з': 'z',
    'и': 'i',
    'й': 'j',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'h',
    'ц': 'ts',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'shch',
    'ъ': '',
    'ы': 'y',
    'ь': '',
    'э': 'e',
    'ю': 'ju',
    'я': 'ja',
  };

  // LATIN TO CYRILLIC CHARACTER MAPPING
  static const Map<String, String> _latinToCyrillic = {
    'shch': 'щ',
    'zh': 'ж',
    'ts': 'ц',
    'ch': 'ч',
    'sh': 'ш',
    'ju': 'ю',
    'ja': 'я',
    'a': 'а', 'b': 'б', 'v': 'в', 'g': 'г', 'd': 'д',
    'e': 'е', 'z': 'з', 'i': 'и', 'j': 'й', 'k': 'к',
    'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п',
    'r': 'р', 's': 'с', 't': 'т', 'u': 'у', 'f': 'ф',
    'h': 'х', 'y': 'ы',
  };

  static final RegExp _normRegex = RegExp(r"['\-\s]");

  static final List<String> _sortedLatinKeys =
      _latinToCyrillic.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  // NORMALIZE TEXT BY STRIPPING SPECIAL CHARACTERS AND LOWERCASE CONVERSION
  static String normalize(String text) {
    return text.toLowerCase().replaceAll(_normRegex, '').trim();
  }

  // CONVERT LATIN INPUT STRING TO CYRILLIC CHARACTERS
  static String latinToCyrillic(String latin) {
    String result = latin.toLowerCase();

    for (final key in _sortedLatinKeys) {
      result = result.replaceAll(key, _latinToCyrillic[key]!);
    }

    return result;
  }

  // CONVERT CYRILLIC INPUT STRING TO LATIN CHARACTERS
  static String cyrillicToLatin(String cyrillic) {
    String result = cyrillic.toLowerCase();

    for (final entry in _cyrillicToLatin.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  // BIDIRECTIONAL SEARCH MATCH VERIFICATION
  static bool matches(String query, String target) {
    final normalizedQuery = normalize(query);
    final normalizedTarget = normalize(target);

    if (normalizedTarget.contains(normalizedQuery)) {
      return true;
    }

    final cyrillicQuery = normalize(latinToCyrillic(normalizedQuery));
    if (normalizedTarget.contains(cyrillicQuery)) {
      return true;
    }

    final latinTarget = normalize(cyrillicToLatin(normalizedTarget));
    if (latinTarget.contains(normalizedQuery)) {
      return true;
    }

    return false;
  }
}
