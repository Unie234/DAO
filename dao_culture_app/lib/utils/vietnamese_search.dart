String normalizeVietnameseSearch(String value) {
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  return value
      .toLowerCase()
      .split('')
      .map((char) => replacements[char] ?? char)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool matchesVietnameseSearch(String query, Iterable<String> values) {
  return vietnameseSearchScore(query, values) > 0;
}

int vietnameseSearchScore(String query, Iterable<String> values) {
  final normalizedQuery = normalizeVietnameseSearch(query);
  if (normalizedQuery.isEmpty) return 1;

  final searchable = normalizeVietnameseSearch(values.join(' '));
  if (searchable.contains(normalizedQuery)) return 100;

  const stopWords = {
    'la',
    'gi',
    'co',
    'cua',
    'nguoi',
    'dao',
    've',
    'nhu',
    'the',
    'nao',
    'cho',
    'biet',
    'bai',
    'viet',
  };
  final tokens = normalizedQuery
      .split(' ')
      .where((token) => token.length >= 2 && !stopWords.contains(token))
      .toSet();
  if (tokens.isEmpty) return 0;

  final matched = tokens.where(searchable.contains).length;
  final minimumMatch = tokens.length <= 2 ? 1 : (tokens.length / 2).ceil();
  return matched >= minimumMatch ? matched * 10 : 0;
}

int vietnameseRelatedScore(
  Iterable<String> sourceValues,
  Iterable<String> candidateValues,
) {
  const ignored = {
    'la',
    'gi',
    'co',
    'cua',
    'nguoi',
    'dao',
    've',
    'va',
    'trong',
    'mot',
    'cac',
    'bai',
    'viet',
    'van',
    'hoa',
    'truyen',
    'thong',
  };
  final source = normalizeVietnameseSearch(sourceValues.join(' '));
  final candidate = normalizeVietnameseSearch(candidateValues.join(' '));
  final candidateTokens = candidate.split(' ').toSet();
  final tokens = source
      .split(' ')
      .where((token) => token.length >= 3 && !ignored.contains(token))
      .toSet();

  var score = 0;
  for (final token in tokens) {
    if (candidateTokens.contains(token)) {
      score += token.length >= 6 ? 4 : 2;
    }
  }
  return score;
}
