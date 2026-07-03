import AppKit
import CoreGraphics
import Foundation

struct IconSize {
    let name: String
    let pixels: Int
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = root.appendingPathComponent("Packaging/EarthAgent.iconset", isDirectory: true)
let websiteAssetsURL = root.appendingPathComponent("Website/assets", isDirectory: true)

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: websiteAssetsURL, withIntermediateDirectories: true)

let iconSizes = [
    IconSize(name: "icon_16x16.png", pixels: 16),
    IconSize(name: "icon_16x16@2x.png", pixels: 32),
    IconSize(name: "icon_32x32.png", pixels: 32),
    IconSize(name: "icon_32x32@2x.png", pixels: 64),
    IconSize(name: "icon_128x128.png", pixels: 128),
    IconSize(name: "icon_128x128@2x.png", pixels: 256),
    IconSize(name: "icon_256x256.png", pixels: 256),
    IconSize(name: "icon_256x256@2x.png", pixels: 512),
    IconSize(name: "icon_512x512.png", pixels: 512),
    IconSize(name: "icon_512x512@2x.png", pixels: 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func drawBlob(_ points: [CGPoint], in rect: CGRect, alpha: CGFloat) {
    guard let first = points.first else { return }
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + first.x * rect.width, y: rect.minY + first.y * rect.height))

    for index in points.indices.dropFirst() {
        let current = CGPoint(x: rect.minX + points[index].x * rect.width, y: rect.minY + points[index].y * rect.height)
        let previous = CGPoint(x: rect.minX + points[index - 1].x * rect.width, y: rect.minY + points[index - 1].y * rect.height)
        let control = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
        path.curve(to: current, controlPoint1: control, controlPoint2: current)
    }
    path.close()

    let gradient = NSGradient(colors: [
        color(0.74, 0.96, 0.50, alpha),
        color(0.12, 0.72, 0.42, alpha),
        color(0.03, 0.40, 0.28, alpha)
    ])
    gradient?.draw(in: path, angle: -42)
}

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size)
    let corner = scale * 0.22
    let inset = scale * 0.045
    let plate = bounds.insetBy(dx: inset, dy: inset)

    let shadow = NSShadow()
    shadow.shadowBlurRadius = scale * 0.05
    shadow.shadowOffset = NSSize(width: 0, height: -scale * 0.02)
    shadow.shadowColor = color(0.0, 0.0, 0.0, 0.42)
    shadow.set()

    let platePath = NSBezierPath(roundedRect: plate, xRadius: corner, yRadius: corner)
    NSGradient(colors: [
        color(0.02, 0.05, 0.10),
        color(0.03, 0.10, 0.20),
        color(0.01, 0.02, 0.06)
    ])?.draw(in: platePath, angle: -34)

    context.saveGState()
    platePath.addClip()

    for i in 0..<90 {
        let x = CGFloat((i * 73) % 997) / 997.0 * scale
        let y = CGFloat((i * 191) % 983) / 983.0 * scale
        let radius = max(1, scale * CGFloat((i % 4) + 1) / 900)
        color(0.77, 0.93, 1.0, CGFloat(0.10 + Double(i % 5) * 0.025)).setFill()
        NSBezierPath(ovalIn: CGRect(x: x, y: y, width: radius, height: radius)).fill()
    }

    context.restoreGState()

    let globeRect = CGRect(x: scale * 0.18, y: scale * 0.15, width: scale * 0.66, height: scale * 0.66)
    let globePath = NSBezierPath(ovalIn: globeRect)

    NSGradient(colors: [
        color(0.76, 0.96, 1.0),
        color(0.05, 0.54, 0.95),
        color(0.02, 0.18, 0.48),
        color(0.0, 0.03, 0.13)
    ])?.draw(in: globePath, relativeCenterPosition: NSPoint(x: -0.30, y: 0.32))

    context.saveGState()
    globePath.addClip()

    for index in 0..<5 {
        let waveRect = CGRect(
            x: globeRect.minX - scale * 0.04,
            y: globeRect.minY + globeRect.height * CGFloat(0.20 + Double(index) * 0.13),
            width: globeRect.width * 1.08,
            height: globeRect.height * CGFloat(0.12 + Double(index) * 0.025)
        )
        color(1, 1, 1, 0.07).setStroke()
        let wave = NSBezierPath(ovalIn: waveRect)
        wave.lineWidth = max(1, scale * 0.002)
        wave.stroke()
    }

    drawBlob([
        CGPoint(x: 0.18, y: 0.62),
        CGPoint(x: 0.28, y: 0.82),
        CGPoint(x: 0.48, y: 0.76),
        CGPoint(x: 0.53, y: 0.56),
        CGPoint(x: 0.35, y: 0.44),
        CGPoint(x: 0.20, y: 0.48)
    ], in: globeRect, alpha: 0.96)

    drawBlob([
        CGPoint(x: 0.54, y: 0.50),
        CGPoint(x: 0.82, y: 0.62),
        CGPoint(x: 0.88, y: 0.42),
        CGPoint(x: 0.77, y: 0.18),
        CGPoint(x: 0.58, y: 0.29)
    ], in: globeRect, alpha: 0.90)

    drawBlob([
        CGPoint(x: 0.14, y: 0.36),
        CGPoint(x: 0.31, y: 0.43),
        CGPoint(x: 0.38, y: 0.24),
        CGPoint(x: 0.24, y: 0.10),
        CGPoint(x: 0.10, y: 0.20)
    ], in: globeRect, alpha: 0.85)

    context.restoreGState()

    NSGradient(colors: [
        color(1, 1, 1, 0.66),
        color(1, 1, 1, 0.14),
        color(1, 1, 1, 0.0)
    ])?.draw(in: NSBezierPath(ovalIn: CGRect(
        x: globeRect.minX + globeRect.width * 0.12,
        y: globeRect.minY + globeRect.height * 0.58,
        width: globeRect.width * 0.48,
        height: globeRect.height * 0.34
    )), angle: -35)

    let shadePath = NSBezierPath(ovalIn: globeRect)
    NSGradient(colors: [
        color(0, 0, 0, 0.0),
        color(0, 0, 0, 0.10),
        color(0, 0, 0, 0.48)
    ])?.draw(in: shadePath, angle: -45)

    color(0.58, 0.90, 1.0, 0.86).setStroke()
    globePath.lineWidth = max(1, scale * 0.012)
    globePath.stroke()

    context.saveGState()
    let orbitClip = NSBezierPath(roundedRect: plate, xRadius: corner, yRadius: corner)
    orbitClip.addClip()

    for (index, orbitScale) in [1.02, 1.20, 1.38].enumerated() {
        let orbitRect = globeRect.insetBy(dx: -globeRect.width * CGFloat(orbitScale - 1) * 0.5, dy: globeRect.height * 0.18)
            .offsetBy(dx: scale * CGFloat(index - 1) * 0.015, dy: scale * CGFloat(index - 1) * 0.018)
        let orbit = NSBezierPath(ovalIn: orbitRect)
        color(index == 1 ? 0.48 : 0.72, index == 2 ? 0.90 : 0.96, 1.0, CGFloat(0.28 - Double(index) * 0.055)).setStroke()
        orbit.lineWidth = max(1, scale * CGFloat(0.006 - Double(index) * 0.001))
        orbit.stroke()
    }

    context.restoreGState()

    let cursorPath = NSBezierPath()
    cursorPath.move(to: CGPoint(x: scale * 0.69, y: scale * 0.34))
    cursorPath.line(to: CGPoint(x: scale * 0.84, y: scale * 0.22))
    cursorPath.line(to: CGPoint(x: scale * 0.76, y: scale * 0.42))
    cursorPath.line(to: CGPoint(x: scale * 0.73, y: scale * 0.35))
    cursorPath.close()
    color(0.98, 1.0, 1.0, 0.96).setFill()
    cursorPath.fill()
    color(0.40, 0.91, 1.0, 0.95).setStroke()
    cursorPath.lineWidth = max(1, scale * 0.01)
    cursorPath.stroke()

    let shine = NSBezierPath(roundedRect: plate.insetBy(dx: scale * 0.025, dy: scale * 0.025), xRadius: corner * 0.82, yRadius: corner * 0.82)
    color(1, 1, 1, 0.18).setStroke()
    shine.lineWidth = max(1, scale * 0.006)
    shine.stroke()

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "EarthAgentIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG for \(url.path)"])
    }
    try png.write(to: url)
}

for size in iconSizes {
    try writePNG(drawIcon(size: size.pixels), to: iconsetURL.appendingPathComponent(size.name))
}

try writePNG(drawIcon(size: 1024), to: websiteAssetsURL.appendingPathComponent("earthagent-dev-icon-1024.png"))
try writePNG(drawIcon(size: 512), to: websiteAssetsURL.appendingPathComponent("earthagent-dev-icon-512.png"))
try writePNG(drawIcon(size: 180), to: websiteAssetsURL.appendingPathComponent("apple-touch-icon.png"))

print("Generated EarthAgent icon assets.")
