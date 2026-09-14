#!/usr/bin/swift
import AppKit
import Foundation

struct Icon {
  let source: String
  let asset: String
  let filename: String
}

let icons = [
  Icon(source: "pocket", asset: "TuckPocket", filename: "pocket"),
  Icon(source: "peek", asset: "TuckPeek", filename: "peek"),
  Icon(source: "buddy", asset: "TuckBuddy", filename: "buddy"),
  Icon(source: "spark", asset: "TuckSpark", filename: "spark")
]

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)

func render(source: URL, destination: URL, pixels: Int) throws {
  guard let image = NSImage(contentsOf: source) else {
    throw NSError(domain: "TuckMenuIcons", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot load \(source.path)"])
  }
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: .alphaFirst,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    throw NSError(domain: "TuckMenuIcons", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create \(pixels) px bitmap"])
  }

  NSGraphicsContext.saveGraphicsState()
  defer { NSGraphicsContext.restoreGraphicsState() }
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
  NSColor.clear.setFill()
  NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()
  NSGraphicsContext.current?.imageInterpolation = .high
  image.draw(
    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
    from: .zero,
    operation: .sourceOver,
    fraction: 1,
    respectFlipped: false,
    hints: [.interpolation: NSImageInterpolation.high]
  )

  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "TuckMenuIcons", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot encode \(destination.path)"])
  }
  try data.write(to: destination, options: .atomic)
}

for icon in icons {
  let source = root.appendingPathComponent("Assets/Tuck/MenuIcons/\(icon.source).svg")
  let destination = root.appendingPathComponent("Tuck/Assets.xcassets/\(icon.asset).imageset", isDirectory: true)
  try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
  try render(source: source, destination: destination.appendingPathComponent("\(icon.filename)-16.png"), pixels: 16)
  try render(source: source, destination: destination.appendingPathComponent("\(icon.filename)-32.png"), pixels: 32)
}
