import CoreImage
import Defaults
import SwiftUI

class ApplicationImage {
  private struct AverageRGBA: Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
  }

  fileprivate static let fallbackImage = NSImage(
    systemSymbolName: "questionmark.app.dashed",
    accessibilityDescription: nil
  )!
  private static let retryInterval: TimeInterval = 60 * 60
  private static let colorContext = CIContext(options: [.workingColorSpace: NSNull()])
  private static let accentColorQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "app.tuck.clipboard.accent-colors"
    queue.qualityOfService = .utility
    queue.maxConcurrentOperationCount = 2
    return queue
  }()

  let bundleIdentifier: String?
  private var image: NSImage?
  private var accentColorCache: NSColor?
  private var accentColorGenerationTask: Task<AverageRGBA?, Never>?
  private var lastChecked: Date?
  private var eventSource: (any DispatchSourceFileSystemObject)?

  init(bundleIdentifier: String?, image: NSImage? = nil) {
    self.bundleIdentifier = bundleIdentifier
    self.image = image
  }

  var nsImage: NSImage {
    guard let bundleIdentifier else {
      return Self.fallbackImage
    }

    if let image {
      return image
    }

    // The image has been queried before but since the application has been deleted.
    // Check from time to time if the application has returned.
    if let lastChecked,
      Date().timeIntervalSince(lastChecked) < Self.retryInterval {
      return Self.fallbackImage
    }
    lastChecked = .now

    if let appURL = NSWorkspace.shared.urlForApplication(
      withBundleIdentifier: bundleIdentifier
    ) {
      let img = NSWorkspace.shared.icon(forFile: appURL.path)
      image = img

      let descriptor = open(appURL.path, O_EVTONLY)
      if descriptor == -1 {
        let errorCode = errno
        print("Error code: \(errorCode)")
        print("Error message: \(String(cString: strerror(errorCode)))")
      } else if descriptor > 0 {
        let source = DispatchSource.makeFileSystemObjectSource(
          fileDescriptor: descriptor,
          eventMask: [.write, .delete],
          queue: DispatchQueue.global()
        )
        eventSource = source
        source.setEventHandler {
          DispatchQueue.main.async {
            let event = source.data
            if event.contains(.delete) {
              // File was deleted.
              print("Deleted", appURL.path)
              source.cancel()
              self.image = nil
              self.accentColorCache = nil
              self.accentColorGenerationTask?.cancel()
              self.accentColorGenerationTask = nil
              self.lastChecked = nil
            } else if event.contains(.write) {
              // File was modified. Fetch new icon
              print("Modified", appURL.path)
              self.image = NSWorkspace.shared.icon(forFile: appURL.path)
              self.accentColorCache = nil
              self.accentColorGenerationTask?.cancel()
              self.accentColorGenerationTask = nil
            }
          }
        }
        source.setCancelHandler {
          close(descriptor)
        }
        source.resume()
      }

      return img
    }

    return Self.fallbackImage
  }

  @MainActor
  func prepareAccentColor() {
    guard accentColorCache == nil, accentColorGenerationTask == nil else { return }
    guard let data = nsImage.tiffRepresentation else { return }

    accentColorGenerationTask = Task {
      await Self.averageRGBA(from: data)
    }
  }

  @MainActor
  func resolvedAccentColor() async -> NSColor {
    if let accentColorCache { return accentColorCache }

    prepareAccentColor()
    guard let task = accentColorGenerationTask else { return .controlAccentColor }
    guard let average = await task.value else {
      accentColorGenerationTask = nil
      return .controlAccentColor
    }

    let resolved = Self.accentColor(from: average)
    accentColorCache = resolved
    accentColorGenerationTask = nil
    return resolved
  }

  private nonisolated static func averageRGBA(from data: Data) async -> AverageRGBA? {
    await withCheckedContinuation { continuation in
      accentColorQueue.addOperation {
        continuation.resume(returning: renderAverageRGBA(from: data))
      }
    }
  }

  private nonisolated static func renderAverageRGBA(from data: Data) -> AverageRGBA? {
    guard
      let inputImage = CIImage(data: data),
      let filter = CIFilter(name: "CIAreaAverage")
    else { return nil }

    filter.setValue(inputImage, forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgRect: inputImage.extent), forKey: kCIInputExtentKey)
    guard let outputImage = filter.outputImage else { return nil }

    var pixels = [UInt8](repeating: 0, count: 4)
    colorContext.render(
      outputImage,
      toBitmap: &pixels,
      rowBytes: 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: CGColorSpaceCreateDeviceRGB()
    )

    return AverageRGBA(red: pixels[0], green: pixels[1], blue: pixels[2], alpha: pixels[3])
  }

  private static func accentColor(from average: AverageRGBA) -> NSColor {
    let alpha = CGFloat(average.alpha) / 255
    guard alpha > 0.06 else { return .controlAccentColor }

    let color = NSColor(
      calibratedRed: min(1, CGFloat(average.red) / 255 / alpha),
      green: min(1, CGFloat(average.green) / 255 / alpha),
      blue: min(1, CGFloat(average.blue) / 255 / alpha),
      alpha: 1
    )
    guard let rgb = color.usingColorSpace(.deviceRGB) else { return color }

    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var normalizedAlpha: CGFloat = 0
    rgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &normalizedAlpha)

    return NSColor(
      calibratedHue: hue,
      saturation: saturation < 0.12 ? saturation : min(max(saturation, 0.4), 0.8),
      brightness: min(max(brightness, 0.44), 0.82),
      alpha: 1
    )
  }
}
