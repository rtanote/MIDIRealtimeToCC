#!/usr/bin/env swift
//
// App Icon Generator for MIDIRealtimeToCC
// Generates macOS app icons in all required sizes
//

import AppKit
import Foundation

func generateAndSaveIcon(size: CGSize, path: String) {
    // Create a bitmap image rep directly with exact size
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    // Background with gradient
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
        NSColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0)
    ])
    let bgPath = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                              xRadius: size.width * 0.2, yRadius: size.height * 0.2)
    gradient?.draw(in: bgPath, angle: -45)

    // Draw MIDI symbol
    NSColor.white.setFill()
    NSColor.white.setStroke()

    let centerX = size.width / 2
    let centerY = size.height / 2

    // Input connector (left)
    let inputRect = NSRect(x: centerX - size.width * 0.35,
                          y: centerY - size.height * 0.15,
                          width: size.width * 0.25,
                          height: size.height * 0.3)
    let inputPath = NSBezierPath(roundedRect: inputRect,
                                xRadius: size.width * 0.05, yRadius: size.height * 0.05)
    inputPath.lineWidth = size.width * 0.02
    inputPath.stroke()

    // Five pins (MIDI style)
    let pinRadius = size.width * 0.02
    let pins = [
        CGPoint(x: inputRect.midX, y: inputRect.midY + size.height * 0.08),
        CGPoint(x: inputRect.midX - size.width * 0.05, y: inputRect.midY),
        CGPoint(x: inputRect.midX + size.width * 0.05, y: inputRect.midY),
        CGPoint(x: inputRect.midX - size.width * 0.05, y: inputRect.midY - size.height * 0.08),
        CGPoint(x: inputRect.midX + size.width * 0.05, y: inputRect.midY - size.height * 0.08)
    ]

    for pin in pins {
        let pinPath = NSBezierPath(ovalIn: NSRect(x: pin.x - pinRadius, y: pin.y - pinRadius,
                                                  width: pinRadius * 2, height: pinRadius * 2))
        pinPath.fill()
    }

    // Arrow (conversion symbol)
    let arrowPath = NSBezierPath()
    arrowPath.move(to: CGPoint(x: centerX - size.width * 0.05, y: centerY))
    arrowPath.line(to: CGPoint(x: centerX + size.width * 0.15, y: centerY))
    arrowPath.lineWidth = size.width * 0.03
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    // Arrow head
    let arrowHead = NSBezierPath()
    arrowHead.move(to: CGPoint(x: centerX + size.width * 0.15, y: centerY))
    arrowHead.line(to: CGPoint(x: centerX + size.width * 0.10, y: centerY + size.height * 0.05))
    arrowHead.line(to: CGPoint(x: centerX + size.width * 0.10, y: centerY - size.height * 0.05))
    arrowHead.close()
    arrowHead.fill()

    // Output (CC label)
    let outputRect = NSRect(x: centerX + size.width * 0.15,
                           y: centerY - size.height * 0.15,
                           width: size.width * 0.25,
                           height: size.height * 0.3)
    let outputPath = NSBezierPath(roundedRect: outputRect,
                                 xRadius: size.width * 0.05, yRadius: size.height * 0.05)
    outputPath.lineWidth = size.width * 0.02
    outputPath.stroke()

    // "CC" text
    let fontSize = size.width * 0.12
    let font = NSFont.boldSystemFont(ofSize: fontSize)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let text = "CC" as NSString
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(x: outputRect.midX - textSize.width / 2,
                         y: outputRect.midY - textSize.height / 2,
                         width: textSize.width,
                         height: textSize.height)
    text.draw(in: textRect, withAttributes: attributes)

    NSGraphicsContext.restoreGraphicsState()

    // Save PNG
    if let pngData = rep.representation(using: .png, properties: [:]) {
        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            print("Saved: \(path) (\(Int(size.width))x\(Int(size.height)))")
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

// Get script directory and construct relative path
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDir = scriptURL.deletingLastPathComponent()
let projectRoot = scriptDir.deletingLastPathComponent()
let baseDir = projectRoot
    .appendingPathComponent("MIDIRealtimeToCC")
    .appendingPathComponent("MIDIRealtimeToCCApp")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")
    .path

let sizes: [(width: CGFloat, height: CGFloat, name: String)] = [
    (16, 16, "icon_16x16.png"),
    (32, 32, "icon_16x16@2x.png"),
    (32, 32, "icon_32x32.png"),
    (64, 64, "icon_32x32@2x.png"),
    (128, 128, "icon_128x128.png"),
    (256, 256, "icon_128x128@2x.png"),
    (256, 256, "icon_256x256.png"),
    (512, 512, "icon_256x256@2x.png"),
    (512, 512, "icon_512x512.png"),
    (1024, 1024, "icon_512x512@2x.png")
]

print("Generating app icons...")
for (width, height, name) in sizes {
    generateAndSaveIcon(size: CGSize(width: width, height: height), path: "\(baseDir)/\(name)")
}

print("\nApp icon generation complete!")
