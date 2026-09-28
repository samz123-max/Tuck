import CoreImage
import Defaults
import SwiftUI

class ApplicationImage {
  fileprivate static let fallbackImage = NSImage(
    systemSymbolName: "questionmark.app.dashed",
    accessibilityDescription: nil
  )!
  private static let retryInterval: TimeInterval = 60 * 60
  private static let colorContext = CIContext(options: [.workingColorSpace: NSNull()])

  let bundleIdentifier: String?
  private var image: NSImage?
  private var accentColorCache: NSColor?
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
              self.lastChecked = nil
            } else if event.contains(.write) {
              // File was modified. Fetch new icon
              print("Modified", appURL.path)
              self.image = NSWorkspace.shared.icon(forFile: appURL.path)
              self.accentColorCache = nil
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

  var accentColor: NSColor {
    if let accentColorCache {
      return accentColorCache
    }

    let resolved = Self.averageColor(of: nsImage) ?? .controlAccentColor
    accentColorCache = resolved
    return resolved
  }

  private static func averageColor(of image: NSImage) -> NSColor? {
    guard
      let data = image.tiffRepresentation,
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

    let alpha = CGFloat(pixels[3]) / 255
    guard alpha > 0.06 else { return nil }

    let color = NSColor(
      calibratedRed: min(1, CGFloat(pixels[0]) / 255 / alpha),
      green: min(1, CGFloat(pixels[1]) / 255 / alpha),
      blue: min(1, CGFloat(pixels[2]) / 255 / alpha),
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
