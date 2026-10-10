import AppKit
import Defaults
import Fuse

// Presentation-only classification. No schema, indexing, image decoding, or clipboard writes.
enum ClipboardCategory: String, CaseIterable, Identifiable {
  case all = "All"
  case text = "Text"
  case links = "Links"
  case images = "Images"

  var id: Self { self }

  func includes(_ item: HistoryItemDecorator) -> Bool {
    self == .all || item.category == self
  }

  static func classify(_ contents: [HistoryItemContent]) -> ClipboardCategory? {
    // Some apps advertise representations they cannot actually provide.
    // Numbers, for example, places a zero-byte PNG beside valid cell text.
    let types = Set(contents.filter { $0.value?.isEmpty == false }.map(\.type))
    // A copied file may carry a thumbnail or text fallback; it is still a file.
    if types.contains(NSPasteboard.PasteboardType.fileURL.rawValue) { return nil }
    if StorageType.images.types.contains(where: { types.contains($0.rawValue) }) { return .images }
    for type in [NSPasteboard.PasteboardType.URL, .string] {
      if let data = contents.first(where: { $0.type == type.rawValue })?.value,
         data.count <= 16_384,
         let string = String(data: data, encoding: .utf8),
         isLink(string) { return .links }
    }
    if StorageType.text.types.contains(where: { types.contains($0.rawValue) }) { return .text }
    return nil
  }

  private static func isLink(_ string: String) -> Bool {
    let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
          let url = URLComponents(string: value), let scheme = url.scheme?.lowercased() else { return false }
    if scheme == "http" || scheme == "https" {
      return !(url.host ?? "").isEmpty
    }
    return scheme == "mailto" && url.path.contains("@") && !url.path.hasPrefix("@")
  }
}

class Search {
  enum Mode: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
    case exact
    case fuzzy
    case regexp
    case mixed

    var id: Self { self }

    var description: String {
      switch self {
      case .exact:
        return NSLocalizedString("Exact", tableName: "GeneralSettings", comment: "")
      case .fuzzy:
        return NSLocalizedString("Fuzzy", tableName: "GeneralSettings", comment: "")
      case .regexp:
        return NSLocalizedString("Regex", tableName: "GeneralSettings", comment: "")
      case .mixed:
        return NSLocalizedString("Mixed", tableName: "GeneralSettings", comment: "")
      }
    }
  }

  struct SearchResult: Equatable {
    var score: Double?
    var object: Searchable
    var ranges: [Range<String.Index>] = []
  }

  typealias Searchable = HistoryItemDecorator

  private let fuse = Fuse(threshold: 0.7) // threshold found by trial-and-error
  private let fuzzySearchLimit = 5_000

  func search(string: String, within: [Searchable], category: ClipboardCategory = .all) -> [SearchResult] {
    let within = category == .all ? within : within.filter { category.includes($0) }
    guard !string.isEmpty else {
      return within.map { SearchResult(object: $0) }
    }

    switch Defaults[.searchMode] {
    case .mixed:
      return mixedSearch(string: string, within: within)
    case .regexp:
      return simpleSearch(string: string, within: within, options: .regularExpression)
    case .fuzzy:
      return fuzzySearch(string: string, within: within)
    default:
      return simpleSearch(string: string, within: within, options: .caseInsensitive)
    }
  }

  private func fuzzySearch(string: String, within: [Searchable]) -> [SearchResult] {
    let pattern = fuse.createPattern(from: string)
    let searchResults: [SearchResult] = within.compactMap { item in
      fuzzySearch(for: pattern, in: item.title, of: item)
    }
    let sortedResults = searchResults.sorted(by: { ($0.score ?? 0) < ($1.score ?? 0) })
    return sortedResults
  }

  private func fuzzySearch(
    for pattern: Fuse.Pattern?,
    in searchString: String,
    of item: Searchable
  ) -> SearchResult? {
    var searchString = searchString
    if searchString.count > fuzzySearchLimit {
      // shortcut to avoid slow search
      let stopIndex = searchString.index(searchString.startIndex, offsetBy: fuzzySearchLimit)
      searchString = "\(searchString[...stopIndex])"
    }

    if let fuzzyResult = fuse.search(pattern, in: searchString) {
      return SearchResult(
        score: fuzzyResult.score,
        object: item,
        ranges: fuzzyResult.ranges.map {
          let startIndex = searchString.startIndex
          let lowerBound = searchString.index(startIndex, offsetBy: $0.lowerBound)
          let upperBound = searchString.index(startIndex, offsetBy: $0.upperBound + 1)

          return lowerBound..<upperBound
        }
      )
    } else {
      return nil
    }
  }

  private func simpleSearch(
    string: String,
    within: [Searchable],
    options: NSString.CompareOptions
  ) -> [SearchResult] {
    return within.compactMap { simpleSearch(for: string, in: $0.title, of: $0, options: options) }
  }

  private func simpleSearch(
    for string: String,
    in searchString: String,
    of item: Searchable,
    options: NSString.CompareOptions
  ) -> SearchResult? {
    if let range = searchString.range(of: string, options: options, range: nil, locale: nil) {
      return SearchResult(object: item, ranges: [range])
    } else {
      return nil
    }
  }

  private func mixedSearch(string: String, within: [Searchable]) -> [SearchResult] {
    var results = simpleSearch(string: string, within: within, options: .caseInsensitive)
    guard results.isEmpty else {
      return results
    }

    results = simpleSearch(string: string, within: within, options: .regularExpression)
    guard results.isEmpty else {
      return results
    }

    results = fuzzySearch(string: string, within: within)
    guard results.isEmpty else {
      return results
    }

    return []
  }
}
