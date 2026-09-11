import AppKit
import KeyboardShortcuts
import SwiftUI

private struct PreviewMetadataRow<Content: View>: View {
  let label: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Text(NSLocalizedString(label, tableName: "PreviewItemView", comment: ""))
        .foregroundStyle(.secondary)
        .frame(width: 78, alignment: .leading)
      content()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .font(.caption)
  }
}

struct PreviewItemView: View {
  static var largeTextThreshold = 1_000

  var item: HistoryItemDecorator

  @ViewBuilder
  func previewImage(content: () -> some View) -> some View {
    content()
      .aspectRatio(contentMode: .fit)
      .clipShape(.rect(cornerRadius: 8))
  }

  @ViewBuilder
  private var previewContent: some View {
    if item.hasImage {
      AsyncView<NSImage?, _, _>(id: item.id) {
        return await item.asyncGetPreviewImage()
      } content: { image in
        if let image {
          previewImage {
            Image(nsImage: image)
              .resizable()
          }
        } else {
          imagePlaceholder(systemImage: "photo.badge.exclamationmark")
        }
      } placeholder: {
        imagePlaceholder()
      }
    } else {
      let text = item.previewText
      if text.count >= Self.largeTextThreshold {
        LargeTextPreviewView(text: text)
          .id("textpreview-\(item.id)")
      } else {
        ScrollView {
          Text(text)
            .font(.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  @ViewBuilder
  private func imagePlaceholder(systemImage: String? = nil) -> some View {
    previewImage {
      ZStack {
        Color.gray.opacity(0.12)
          .frame(
            idealWidth: HistoryItemDecorator.previewImageSize.width,
            idealHeight: HistoryItemDecorator.previewImageSize.height
          )
        if let systemImage {
          Image(systemName: systemImage)
            .symbolRenderingMode(.multicolor)
        } else {
          ProgressView()
        }
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      previewContent
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }

      VStack(alignment: .leading, spacing: 7) {
        if let application = item.application {
          PreviewMetadataRow(label: "Application") {
            HStack(spacing: 5) {
              AppImageView(
                appImage: item.applicationImage,
                size: NSSize(width: 13, height: 13)
              )
              Text(application)
            }
          }
        }

        if item.hasImage, let image = item.item.image {
          PreviewMetadataRow(label: "Dimensions") {
            Text("\(Int(image.pixelSize.width))×\(Int(image.pixelSize.height))")
          }
        }

        PreviewMetadataRow(label: "LastCopyTime") {
          Text(item.item.lastCopiedAt, style: .relative)
        }

        PreviewMetadataRow(label: "FirstCopyTime") {
          Text(item.item.firstCopiedAt.formatted(date: .abbreviated, time: .shortened))
        }

        PreviewMetadataRow(label: "NumberOfCopies") {
          Text(String(item.item.numberOfCopies))
        }
      }
      .padding(.horizontal, 4)
    }
    .controlSize(.small)
  }
}

struct LargeTextPreviewView: NSViewRepresentable {
  let text: String

  func makeNSView(context: Context) -> NSScrollView {
    return Self.makeScrollView(text: text)
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView, textView.string != text else {
      return
    }

    textView.string = text
  }

  static func makeScrollView(text: String) -> NSScrollView {
    let textView = NSTextView(usingTextLayoutManager: true)
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = false
    textView.drawsBackground = false
    textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    textView.textColor = .labelColor
    textView.textContainerInset = .zero
    textView.minSize = .zero
    textView.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.autoresizingMask = [.width]
    textView.textContainer?.lineFragmentPadding = 0
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.heightTracksTextView = false
    textView.string = text

    let scrollView = NSScrollView()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false
    return scrollView
  }
}
