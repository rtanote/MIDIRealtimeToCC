#!/usr/bin/env swift
//
// Menu Bar Icon Generator for MIDIRealtimeToCC
// Generates template icons for the menu bar (adapts to light/dark mode)
//

import AppKit
import Foundation

func generateMenuBarIcon(size: CGSize, template: Bool, path: String) {
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

    // For template images, use black color (will be converted to white/dark by system)
    let color = template ? NSColor.black : NSColor.white
    color.setFill()
    color.setStroke()

    let centerX = size.width / 2
    let centerY = size.height / 2

    // Simplified MIDI connector (left side)
    let connectorWidth = size.width * 0.28
    let connectorHeight = size.height * 0.5
    let connectorX = size.width * 0.1
    let connectorY = centerY - connectorHeight / 2

    let connectorPath = NSBezierPath(roundedRect: NSRect(x: connectorX, y: connectorY,
                                                         width: connectorWidth, height: connectorHeight),
                                    xRadius: size.width * 0.04, yRadius: size.height * 0.04)
    connectorPath.lineWidth = size.width * 0.06
    connectorPath.stroke()

    // Three visible pins in connector
    let pinRadius = size.width * 0.04
    let pinCenterX = connectorX + connectorWidth / 2
    let pins = [
        CGPoint(x: pinCenterX, y: centerY),
        CGPoint(x: pinCenterX - size.width * 0.08, y: centerY - size.height * 0.12),
        CGPoint(x: pinCenterX + size.width * 0.08, y: centerY - size.height * 0.12)
    ]

    for pin in pins {
        let pinPath = NSBezierPath(ovalIn: NSRect(x: pin.x - pinRadius, y: pin.y - pinRadius,
                                                  width: pinRadius * 2, height: pinRadius * 2))
        pinPath.fill()
    }

    // Arrow (conversion)
    let arrowStartX = connectorX + connectorWidth + size.width * 0.05
    let arrowEndX = centerX + size.width * 0.15

    let arrowPath = NSBezierPath()
    arrowPath.move(to: CGPoint(x: arrowStartX, y: centerY))
    arrowPath.line(to: CGPoint(x: arrowEndX, y: centerY))
    arrowPath.lineWidth = size.width * 0.08
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    // Arrow head
    let arrowHeadSize = size.width * 0.12
    let arrowHead = NSBezierPath()
    arrowHead.move(to: CGPoint(x: arrowEndX, y: centerY))
    arrowHead.line(to: CGPoint(x: arrowEndX - arrowHeadSize, y: centerY + arrowHeadSize * 0.6))
    arrowHead.line(to: CGPoint(x: arrowEndX - arrowHeadSize, y: centerY - arrowHeadSize * 0.6))
    arrowHead.close()
    arrowHead.fill()

    // "CC" text on the right
    let fontSize = size.height * 0.35
    let font = NSFont.boldSystemFont(ofSize: fontSize)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let text = "CC" as NSString
    let textSize = text.size(withAttributes: attributes)
    let textX = size.width - textSize.width - size.width * 0.08
    let textY = centerY - textSize.height / 2

    text.draw(at: CGPoint(x: textX, y: textY), withAttributes: attributes)

    NSGraphicsContext.restoreGraphicsState()

    // Save PNG
    if let pngData = rep.representation(using: .png, properties: [:]) {
        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            print("Saved: \(path) (\(Int(size.width))x\(Int(size.height))) - Template: \(template)")
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
    .path

// Create MenuBarIcon asset
let menuBarIconDir = "\(baseDir)/MenuBarIcon.imageset"
try? FileManager.default.createDirectory(atPath: menuBarIconDir, withIntermediateDirectories: true)

// Generate template icons (for menu bar - will adapt to light/dark mode)
print("Generating menu bar icons...")
generateMenuBarIcon(size: CGSize(width: 18, height: 18), template: true, path: "\(menuBarIconDir)/menubar_icon_18.png")
generateMenuBarIcon(size: CGSize(width: 36, height: 36), template: true, path: "\(menuBarIconDir)/menubar_icon_18@2x.png")
generateMenuBarIcon(size: CGSize(width: 54, height: 54), template: true, path: "\(menuBarIconDir)/menubar_icon_18@3x.png")

// Create Contents.json for MenuBarIcon
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "menubar_icon_18.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "menubar_icon_18@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "menubar_icon_18@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
"""

try? contentsJSON.write(toFile: "\(menuBarIconDir)/Contents.json", atomically: true, encoding: .utf8)

print("\nMenu bar icon generation complete!")
