// Renders the GrammarBar app icon and writes Resources/AppIcon.icns.
//
//   swift scripts/make-icon.swift
//
// The design follows the macOS icon grid: a rounded plate inset in a 1024 pt canvas with a soft
// shadow, a blue gradient, and the menu bar SF Symbol ("text.badge.checkmark") in white.

import AppKit

let canvas: CGFloat = 1024
let plateRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185

func renderIcon() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let plate = NSBezierPath(roundedRect: plateRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Drop shadow under the plate.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor(srgbRed: 0.04, green: 0.42, blue: 0.92, alpha: 1).setFill()
    plate.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Blue gradient, lighter at the top.
    NSGradient(colors: [
        NSColor(srgbRed: 0.33, green: 0.68, blue: 1.00, alpha: 1),
        NSColor(srgbRed: 0.04, green: 0.45, blue: 0.96, alpha: 1),
        NSColor(srgbRed: 0.02, green: 0.33, blue: 0.80, alpha: 1),
    ])!.draw(in: plate, angle: -90)

    // Subtle top highlight.
    NSGraphicsContext.saveGraphicsState()
    plate.addClip()
    NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: NSColor.white.withAlphaComponent(0))!
        .draw(in: NSRect(x: plateRect.minX, y: plateRect.midY, width: plateRect.width, height: plateRect.height / 2), angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Symbol, centred in the plate.
    let config = NSImage.SymbolConfiguration(pointSize: 440, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let size = symbol.size
    let origin = NSPoint(x: plateRect.midX - size.width / 2, y: plateRect.midY - size.height / 2)
    symbol.draw(in: NSRect(origin: origin, size: size))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func run(_ tool: String, _ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: tool)
    p.arguments = args
    p.standardOutput = FileHandle.nullDevice
    try! p.run()
    p.waitUntilExit()
    precondition(p.terminationStatus == 0, "\(tool) failed")
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources")
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

let master = iconset.appendingPathComponent("icon_512x512@2x.png")
try! renderIcon().representation(using: .png, properties: [:])!.write(to: master)

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
                   ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512), ("512x512", 512)] {
    run("/usr/bin/sips", ["-z", "\(px)", "\(px)", master.path, "--out", iconset.appendingPathComponent("icon_\(name).png").path])
}
run("/usr/bin/iconutil", ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path])
try? FileManager.default.copyItem(at: master, to: FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-preview.png"))
print("Wrote \(resources.appendingPathComponent("AppIcon.icns").path)")
