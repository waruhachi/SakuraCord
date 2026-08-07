import AppKit
@testable import SakuraCord
import Testing

@MainActor
@Test func `native timeline clips downloaded avatars to a circle`() throws {
    let size = 40
    let frame = CGRect(x: 0, y: 0, width: size, height: size)
    let url = try #require(URL(string: "https://cdn.example/avatar-circle.png"))
    let key = NativeTimelineMediaKey.avatar(url)
    let image = NSImage(size: frame.size, flipped: false) { imageFrame in
        NSColor.white.setFill()
        imageFrame.fill()
        return true
    }
    let store = NativeTimelineMediaStore.shared
    store.cacheImageForTesting(image, for: key)
    defer { store.evictVolatileImageForTesting(for: key) }

    let bitmap = try renderBitmap(size: size) { frame in
        NativeTimelineRowPainter.avatar(name: "Sakura", url: url, in: frame)
    }

    let center = try #require(bitmap.colorAt(x: 20, y: 20))
    let cardinal = try #require(bitmap.colorAt(x: 20, y: 2))
    let outsideCircle = try #require(bitmap.colorAt(x: 5, y: 5))

    #expect(center.alphaComponent > 0.95)
    #expect(cardinal.alphaComponent > 0.95)
    #expect(outsideCircle.alphaComponent < 0.05)
}

@MainActor
@Test func `native timeline preserves concentric clipping for rounded media`() throws {
    let size = 40
    let image = NSImage(
        size: NSSize(width: size, height: size),
        flipped: false
    ) { frame in
        NSColor.white.setFill()
        frame.fill()
        return true
    }
    let bitmap = try renderBitmap(size: size) { frame in
        NativeTimelineRowPainter.drawImage(
            image,
            in: frame,
            cornerRadius: CGFloat(size) / 2,
            fillsFrame: true
        )
    }

    let interior = try #require(bitmap.colorAt(x: 20, y: 5))
    let clippedCorner = try #require(bitmap.colorAt(x: 1, y: 1))

    #expect(interior.alphaComponent > 0.95)
    #expect(clippedCorner.alphaComponent < 0.05)
}

@MainActor
private func renderBitmap(
    size: Int,
    draw: (CGRect) -> Void
) throws -> NSBitmapImageRep {
    let frame = CGRect(x: 0, y: 0, width: size, height: size)
    let bitmap = try #require(NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ))
    let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
    let previousContext = NSGraphicsContext.current
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.current = previousContext }

    context.cgContext.clear(frame)
    draw(frame)
    context.flushGraphics()
    return bitmap
}
