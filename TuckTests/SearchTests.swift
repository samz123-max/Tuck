import XCTest
import Defaults
@testable import Tuck

class SearchTests: XCTestCase {
  let savedSearchMode = Defaults[.searchMode]
  var items: [Search.Searchable]!

  override func tearDown() {
    super.tearDown()
    Defaults[.searchMode] = savedSearchMode
  }

  @MainActor
  func testSimpleSearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.exact
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(from: 10, to: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 8, to: 8, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(from: 8, to: 8, in: items[2])]
      )
    ])
    XCTAssertEqual(search("foo"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(from: 0, to: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 0, to: 2, in: items[1])]
      )
    ])
    XCTAssertEqual(search("za"), [
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 8, to: 9, in: items[1])]
      )
    ])
    XCTAssertEqual(search("yyy"), [
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(from: 4, to: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [])
    XCTAssertEqual(search("m"), [])
  }

  @MainActor
  func testFuzzySearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.fuzzy
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z"), [
      Search.SearchResult(
        score: 0.08,
        object: items[1],
        ranges: [range(from: 8, to: 8, in: items[1]), range(from: 10, to: 10, in: items[1])]
      ),
      Search.SearchResult(
        score: 0.08,
        object: items[2],
        ranges: [range(from: 8, to: 10, in: items[2])]
      ),
      Search.SearchResult(
        score: 0.1,
        object: items[0],
        ranges: [range(from: 10, to: 10, in: items[0])]
      )
    ])
    XCTAssertEqual(search("foo"), [
      Search.SearchResult(
        score: 0.0,
        object: items[0],
        ranges: [range(from: 0, to: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: 0.0,
        object: items[1],
        ranges: [range(from: 0, to: 2, in: items[1])]
      )
    ])
    XCTAssertEqual(search("za"), [
      Search.SearchResult(
        score: 0.08,
        object: items[1],
        ranges: [range(from: 5, to: 5, in: items[1]), range(from: 8, to: 9, in: items[1])]
      ),
      Search.SearchResult(
        score: 0.54,
        object: items[0],
        ranges: [range(from: 5, to: 5, in: items[0]), range(from: 9, to: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: 0.58,
        object: items[2],
        ranges: [range(from: 8, to: 10, in: items[2])]
      )
    ])
    XCTAssertEqual(search("yyy"), [
      Search.SearchResult(
        score: 0.04,
        object: items[2],
        ranges: [range(from: 4, to: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [
      Search.SearchResult(
        score: 0.6666666666666666,
        object: items[0],
        ranges: [
          range(from: 0, to: 0, in: items[0]),
          range(from: 4, to: 4, in: items[0]),
          range(from: 8, to: 8, in: items[0])
        ]
      ),
      Search.SearchResult(
        score: 0.6666666666666666,
        object: items[1],
        ranges: [range(from: 0, to: 0, in: items[1]), range(from: 4, to: 4, in: items[1])])
    ])
    XCTAssertEqual(search("m"), [])
  }

  @MainActor
  func testRegexpSearch() { // swiftlint:disable:this function_body_length
    Defaults[.searchMode] = Search.Mode.regexp
    items = [
      HistoryItemDecorator(historyItemWithTitle("foo bar baz")),
      HistoryItemDecorator(historyItemWithTitle("foo bar zaz")),
      HistoryItemDecorator(historyItemWithTitle("xxx yyy zzz"))
    ]

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z+"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(from: 10, to: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 8, to: 8, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(from: 8, to: 10, in: items[2])]
      )
    ])
    XCTAssertEqual(search("z*"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(from: 0, to: -1, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 0, to: -1, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(from: 0, to: -1, in: items[2])]
      )
    ])
    XCTAssertEqual(search("^foo"), [
      Search.SearchResult(
        score: nil,
        object: items[0], ranges: [range(from: 0, to: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1], ranges: [range(from: 0, to: 2, in: items[1])]
      )
    ])
    XCTAssertEqual(search(" za"), [
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(from: 7, to: 9, in: items[1])]
      )
    ])
    XCTAssertEqual(search("[y]+"), [
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(from: 4, to: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [])
    XCTAssertEqual(search("m"), [])
  }

  private func search(_ string: String) -> [Search.SearchResult] {
    return Search().search(string: string, within: items)
  }

  @MainActor
  func testClipboardClassification() {
    func content(_ type: NSPasteboard.PasteboardType, _ value: String = "sample") -> HistoryItemContent {
      HistoryItemContent(type: type.rawValue, value: Data(value.utf8))
    }
    XCTAssertEqual(ClipboardCategory.classify([content(.string, "Meeting notes")]), .text)
    XCTAssertEqual(ClipboardCategory.classify([content(.rtf)]), .text)
    XCTAssertEqual(ClipboardCategory.classify([content(.html)]), .text)
    for url in ["https://apple.com", " HTTPs://apple.com/mac?ref=home\n", "mailto:hello@example.com"] {
      XCTAssertEqual(ClipboardCategory.classify([content(.string, url)]), .links)
    }
    for text in ["Visit https://apple.com", "https://", "https://apple.com and more", "apple.com", "file:///tmp/a"] {
      XCTAssertEqual(ClipboardCategory.classify([content(.string, text)]), .text)
    }
    XCTAssertEqual(ClipboardCategory.classify([content(.URL, "https://apple.com")]), .links)
    for type in StorageType.images.types {
      XCTAssertEqual(ClipboardCategory.classify([content(type), content(.string, "https://apple.com")]), .images)
    }
    XCTAssertNil(ClipboardCategory.classify([content(.fileURL), content(.png), content(.string)]))
    XCTAssertNil(ClipboardCategory.classify([]))
    XCTAssertNil(ClipboardCategory.classify([HistoryItemContent(type: "public.png")]))
    XCTAssertEqual(
      ClipboardCategory.classify([
        HistoryItemContent(type: NSPasteboard.PasteboardType.png.rawValue, value: Data()),
        content(.string, "Numbers cell")
      ]),
      .text
    )
    XCTAssertNil(ClipboardCategory.classify([content(.init("custom.format"))]))
  }

  @MainActor
  func testCategoryAndSearchComposeWithoutChangingContentsOrPins() {
    Defaults[.searchMode] = .exact
    let link = HistoryItemDecorator(historyItemWithTitle("https://apple.com/mac"))
    let text = HistoryItemDecorator(historyItemWithTitle("Apple meeting notes"))
    let photo = historyItemWithTitle("poster")
    photo.contents = [HistoryItemContent(type: NSPasteboard.PasteboardType.png.rawValue, value: Data([1, 2, 3]))]
    photo.pin = "b"
    let image = HistoryItemDecorator(photo)
    let originals = photo.contents.map(\.value)
    let candidates = [link, text, image]
    let engine = Search()
    XCTAssertEqual(engine.search(string: "Apple", within: candidates, category: .links).map(\.object), [link])
    XCTAssertEqual(engine.search(string: "Apple", within: candidates, category: .text).map(\.object), [text])
    XCTAssertEqual(engine.search(string: "poster", within: candidates, category: .images).map(\.object), [image])
    XCTAssertTrue(engine.search(string: "Apple", within: candidates, category: .images).isEmpty)
    XCTAssertEqual(engine.search(string: "", within: candidates, category: .all).map(\.object), candidates)
    XCTAssertEqual(photo.contents.map(\.value), originals)
    XCTAssertEqual(photo.pin, "b")
  }

  @MainActor
  func testAllCategoryPreservesEverySearchMode() {
    let candidates = [HistoryItemDecorator(historyItemWithTitle("apple notes")),
                      HistoryItemDecorator(historyItemWithTitle("https://apple.com"))]
    let engine = Search()
    for mode in Search.Mode.allCases {
      Defaults[.searchMode] = mode
      for query in ["", "apple", "aple", "[a-z]+", "nothing"] {
        XCTAssertEqual(engine.search(string: query, within: candidates),
                       engine.search(string: query, within: candidates, category: .all))
      }
    }
  }

  @MainActor
  func testMixedSearchRefinesWithinCategoryBeforeFallback() {
    Defaults[.searchMode] = .mixed
    let text = HistoryItemDecorator(historyItemWithTitle("aple"))
    let link = HistoryItemDecorator(historyItemWithTitle("https://apple.com"))
    XCTAssertEqual(Search().search(string: "aple", within: [text, link], category: .links).map(\.object), [link])
  }

  @MainActor
  func testLargeHistoryFilteringPerformance() {
    Defaults[.searchMode] = .exact
    let candidates = (0..<10_000).map { index in
      HistoryItemDecorator(historyItemWithTitle(index.isMultiple(of: 2)
        ? "https://example.com/poster/\(index)" : "Meeting notes \(index)"))
    }
    measure {
      let result = Search().search(string: "poster", within: candidates, category: .links)
      XCTAssertEqual(result.count, 5_000)
    }
  }

  // swiftlint:disable:next identifier_name
  private func range(from: Int, to: Int, in item: HistoryItemDecorator) -> Range<String.Index> {
    let startIndex = item.title.startIndex
    let lowerBound = item.title.index(startIndex, offsetBy: from)
    let upperBound = item.title.index(startIndex, offsetBy: to + 1)

    return lowerBound..<upperBound
  }

  @MainActor
  private func historyItemWithTitle(_ value: String?) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value?.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }
}
