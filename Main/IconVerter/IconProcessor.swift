import Cocoa
import Combine

struct IconSize: Identifiable {
    let id = UUID()
    let size: Int
    let role: String
}

let SIZES: [IconSize] = [
    IconSize(size: 32,   role: "16pt @2×"),
    IconSize(size: 64,   role: "32pt @2×"),
    IconSize(size: 128,  role: "128 pt"),
    IconSize(size: 256,  role: "256 pt"),
    IconSize(size: 512,  role: "512 pt"),
    IconSize(size: 1024, role: "512pt @2×"),
]

class IconProcessor: ObservableObject {
    @Published var sourceImage: NSImage?
    @Published var fileName: String = ""
    @Published var fileInfo: String = ""
    @Published var generatedPNGs: [Int: Data] = [:]
    @Published var isGenerating: Bool = false
    @Published var usePadding: Bool = true
    @Published var paddingPercent: Double = 6.0
    @Published var hasImage: Bool = false
    @Published var completedSizes: Set<Int> = []

    // Explicit init required for ObservableObject with stored properties
    init() {}

    func loadImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = NSImage(contentsOf: url) else { return }
            guard let tiffData = image.tiffRepresentation,
                  let imageRep = NSBitmapImageRep(data: tiffData) else { return }

            let pxWidth  = imageRep.pixelsWide
            let pxHeight = imageRep.pixelsHigh
            let warn = (pxWidth < 512 || pxHeight < 512) ? " · ⚠ small source" : ""

            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = (attrs?[.size] as? Int) ?? 0

            DispatchQueue.main.async {
                self.sourceImage = image
                self.fileName = url.lastPathComponent
                self.fileInfo = "\(pxWidth) × \(pxHeight) px  ·  \(fileSize / 1024) KB\(warn)"
                self.hasImage = true
                self.generate()
            }
        }
    }

    func reset() {
        sourceImage = nil
        fileName = ""
        fileInfo = ""
        generatedPNGs = [:]
        completedSizes = []
        hasImage = false
        isGenerating = false
    }

    func generate() {
        guard let src = sourceImage else { return }
        isGenerating = true
        completedSizes = []
        generatedPNGs = [:]

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let padRatio = self.usePadding ? (self.paddingPercent / 100.0) : 0.0

            for sizeInfo in SIZES {
                if let data = self.resizeTo(targetSize: sizeInfo.size, padRatio: padRatio, source: src) {
                    DispatchQueue.main.async {
                        self.generatedPNGs[sizeInfo.size] = data
                        self.completedSizes.insert(sizeInfo.size)
                    }
                }
            }

            DispatchQueue.main.async {
                self.isGenerating = false
            }
        }
    }

    // MARK: - Resize (pixel-perfect port of the JS canvas logic)
    private func resizeTo(targetSize: Int, padRatio: Double, source: NSImage) -> Data? {
        guard let tiffData = source.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let cgImage = imageRep.cgImage else {
            return nil
        }

        let srcWidth  = cgImage.width
        let srcHeight = cgImage.height
        let raw = min(srcWidth, srcHeight)
        let sx = (srcWidth - raw) / 2
        let sy = (srcHeight - raw) / 2
        let initial = min(1024, raw)
        let pad = Int(Double(initial) * padRatio)
        let artwork = initial - 2 * pad

        // Initial canvas
        guard let initialContext = CGContext(
            data: nil,
            width: initial,
            height: initial,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        initialContext.interpolationQuality = .high

        guard let cropped = cgImage.cropping(to: CGRect(x: sx, y: sy, width: raw, height: raw)) else {
            return nil
        }

        initialContext.draw(
            cropped,
            in: CGRect(x: pad, y: pad, width: artwork, height: artwork)
        )

        guard var currentImage = initialContext.makeImage() else { return nil }
        var currentSize = initial

        // Multi-step halving (Math.round exact match)
        while currentSize > targetSize * 2 {
            let newSize = Int((Double(currentSize) / 2.0).rounded())
            guard let newContext = CGContext(
                data: nil,
                width: newSize,
                height: newSize,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { break }

            newContext.interpolationQuality = .high
            newContext.draw(currentImage, in: CGRect(x: 0, y: 0, width: newSize, height: newSize))

            if let newImage = newContext.makeImage() {
                currentImage = newImage
                currentSize = newSize
            } else {
                break
            }
        }

        // Final resize if needed
        if currentSize != targetSize {
            guard let finalContext = CGContext(
                data: nil,
                width: targetSize,
                height: targetSize,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            finalContext.interpolationQuality = .high
            finalContext.draw(currentImage, in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))

            guard let finalImage = finalContext.makeImage() else { return nil }
            currentImage = finalImage
        }

        let bitmap = NSBitmapImageRep(cgImage: currentImage)
        bitmap.size = NSSize(width: targetSize, height: targetSize)
        return bitmap.representation(using: .png, properties: [:])
    }

    // MARK: - ICNS builder (exact binary port of the JS logic)
    func buildICNS() -> Data? {
        let chunks: [(tag: String, data: Data)] = [
            ("ic07", generatedPNGs[128]),
            ("ic08", generatedPNGs[256]),
            ("ic09", generatedPNGs[512]),
            ("ic10", generatedPNGs[1024]),
            ("ic11", generatedPNGs[32]),
            ("ic12", generatedPNGs[64]),
            ("ic13", generatedPNGs[256]),
            ("ic14", generatedPNGs[512]),
        ].compactMap { tag, data in
            guard let data = data else { return nil }
            return (tag, data)
        }

        let tocDataLen = chunks.count * 8
        let tocChunkSize = 8 + tocDataLen

        var total = 8 + tocChunkSize
        for (_, data) in chunks {
            total += 8 + data.count
        }

        var result = Data()
        result.reserveCapacity(total)

        // icns header
        result.append(contentsOf: "icns".utf8)
        result.append(bigEndianBytes(from: UInt32(total)))

        // TOC chunk
        result.append(contentsOf: "TOC ".utf8)
        result.append(bigEndianBytes(from: UInt32(tocChunkSize)))
        for (tag, data) in chunks {
            result.append(contentsOf: tag.utf8)
            result.append(bigEndianBytes(from: UInt32(8 + data.count)))
        }

        // Data chunks
        for (tag, data) in chunks {
            result.append(contentsOf: tag.utf8)
            result.append(bigEndianBytes(from: UInt32(8 + data.count)))
            result.append(data)
        }

        return result
    }

    // MARK: - ZIP builder (uses system /usr/bin/zip)
    func buildZIP() -> Data? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let iconsetDir = tempDir.appendingPathComponent("AppIcon.iconset")
            try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

            let iconsetFiles: [(Int, String)] = [
                (32,   "icon_16x16@2x.png"),
                (32,   "icon_32x32.png"),
                (64,   "icon_32x32@2x.png"),
                (128,  "icon_128x128.png"),
                (256,  "icon_128x128@2x.png"),
                (256,  "icon_256x256.png"),
                (512,  "icon_256x256@2x.png"),
                (512,  "icon_512x512.png"),
                (1024, "icon_512x512@2x.png"),
            ]

            for (sz, name) in iconsetFiles {
                if let data = generatedPNGs[sz] {
                    let fileURL = iconsetDir.appendingPathComponent(name)
                    try data.write(to: fileURL)
                }
            }

            let zipURL = tempDir.appendingPathComponent("AppIcon.iconset.zip")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-r", zipURL.path, "AppIcon.iconset"]
            process.currentDirectoryURL = tempDir

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            return try Data(contentsOf: zipURL)
        } catch {
            print("ZIP error: \(error)")
            return nil
        }
    }
}

// MARK: - UInt32 big-endian helper (fileprivate to avoid conflicts)
fileprivate func bigEndianBytes(from value: UInt32) -> Data {
    var bigEndian = value.bigEndian
    return withUnsafeBytes(of: &bigEndian) { Data($0) }
}
