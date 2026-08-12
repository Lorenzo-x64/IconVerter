import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var processor = IconProcessor()
    @State private var isDropTargeted = false
    @State private var isDropHovered = false
    @State private var isBrowseHovered = false
    @State private var isBrowsePressed = false
    @State private var isChangeHovered = false
    @State private var isChangePressed = false
    @State private var isIcnsHovered = false
    @State private var isIcnsPressed = false
    @State private var isZipHovered = false
    @State private var isZipPressed = false
    @State private var isCloseHovered = false
    @State private var isMinHovered = false
    @State private var isZoomHovered = false
    @Environment(\.colorScheme) private var colorScheme

    private var bg: Color {
        colorScheme == .dark
            ? Color(white: 0.078)
            : Color(red: 0.910, green: 0.910, blue: 0.929)
    }

    private var surface: Color {
        colorScheme == .dark
            ? Color(white: 0.173, opacity: 0.80)
            : Color(white: 1.0, opacity: 0.75)
    }

    private var surfaceUp: Color {
        colorScheme == .dark
            ? Color(white: 0.220, opacity: 0.95)
            : Color(white: 1.0, opacity: 0.95)
    }

    private var surfaceDown: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.35)
            : Color.black.opacity(0.04)
    }

    private var border: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.08)
    }

    private var borderUp: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : Color.black.opacity(0.14)
    }

    private var text: Color {
        colorScheme == .dark
            ? Color(red: 0.949, green: 0.949, blue: 0.969)
            : Color(red: 0.110, green: 0.110, blue: 0.118)
    }

    private var text2: Color {
        colorScheme == .dark
            ? Color(red: 0.922, green: 0.922, blue: 0.961, opacity: 0.68)
            : Color(red: 0.431, green: 0.431, blue: 0.451)
    }

    private var text3: Color {
        colorScheme == .dark
            ? Color(red: 0.922, green: 0.922, blue: 0.961, opacity: 0.32)
            : Color(red: 0.682, green: 0.682, blue: 0.698)
    }

    private var accent: Color {
        colorScheme == .dark
            ? Color(red: 0.039, green: 0.518, blue: 1.0)
            : Color(red: 0.0, green: 0.478, blue: 1.0)
    }

    private var accentDark: Color {
        colorScheme == .dark
            ? Color(red: 0.251, green: 0.612, blue: 1.0)
            : Color(red: 0.0, green: 0.384, blue: 0.8)
    }

    private var ok: Color {
        colorScheme == .dark
            ? Color(red: 0.196, green: 0.843, blue: 0.294)
            : Color(red: 0.188, green: 0.722, blue: 0.306)
    }

    private var okDim: Color {
        colorScheme == .dark
            ? Color(red: 0.196, green: 0.843, blue: 0.294, opacity: 0.12)
            : Color(red: 0.188, green: 0.722, blue: 0.306, opacity: 0.15)
    }

    private let tcClose = Color(red: 1.0, green: 0.373, blue: 0.341)
    private let tcMin   = Color(red: 1.0, green: 0.741, blue: 0.184)
    private let tcMax   = Color(red: 0.157, green: 0.784, blue: 0.251)

    private var anyTrafficLightHovered: Bool {
        isCloseHovered || isMinHovered || isZoomHovered
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            if !processor.hasImage {
                dropZone
                    .padding(20)
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .scale(scale: 0.96))
                                .combined(with: .offset(y: -6)),
                            removal: .opacity
                                .combined(with: .scale(scale: 1.04))
                                .combined(with: .offset(y: 6))
                        )
                    )
            } else {
                ScrollView(showsIndicators: false) {
                    resultsPanel
                        .padding(20)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 1.04))
                            .combined(with: .offset(y: 6)),
                        removal: .opacity
                            .combined(with: .scale(scale: 0.96))
                            .combined(with: .offset(y: -6))
                    )
                )
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: processor.hasImage
        )
        .frame(width: 596)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.60) : Color.black.opacity(0.18),
                    radius: colorScheme == .dark ? 80 : 60,
                    x: 0, y: colorScheme == .dark ? 24 : 20
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.10),
                    radius: colorScheme == .dark ? 20 : 16,
                    x: 0, y: colorScheme == .dark ? 4 : 4
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.14),
                    lineWidth: 0.5
                )
        )
        .onChange(of: processor.hasImage) { _, hasImage in
            animateWindowCentered(hasImage: hasImage)
        }
    }

    private func animateWindowCentered(hasImage: Bool) {
        guard let window = NSApplication.shared.windows.first else { return }
        let targetHeight: CGFloat = hasImage ? 600 : 440
        let currentFrame = window.frame
        let delta = targetHeight - currentFrame.height

        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y - delta / 2,
            width: 596,
            height: targetHeight
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            context.allowsImplicitAnimation = true
            window.animator().setFrame(newFrame, display: true)
        }
    }

    private var titleBar: some View {
        ZStack {
            surfaceUp
            HStack(spacing: 8) {
                TrafficLightButton(
                    color: tcClose,
                    icon: "xmark",
                    isHovered: $isCloseHovered,
                    showIcon: anyTrafficLightHovered,
                    action: { NSApplication.shared.terminate(nil) }
                )

                TrafficLightButton(
                    color: tcMin,
                    icon: "minus",
                    isHovered: $isMinHovered,
                    showIcon: anyTrafficLightHovered,
                    action: { NSApplication.shared.windows.first?.miniaturize(nil) }
                )

                TrafficLightButton(
                    color: tcMax,
                    icon: "arrow.up.left.and.arrow.down.right",
                    isHovered: $isZoomHovered,
                    showIcon: anyTrafficLightHovered,
                    action: {}
                )

                Spacer()
            }
            .padding(.horizontal, 18)
            Text("Icon Converter")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(text.opacity(0.75))
        }
        .frame(height: 48)
        .overlay(
            Rectangle().fill(border).frame(height: 0.5)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
    }

    private var dropZone: some View {
        VStack(spacing: 0) {
            DropZoneIcon()
                .stroke(
                    isDropTargeted || isDropHovered ? text.opacity(0.5) : text3.opacity(0.28),
                    lineWidth: 2.2
                )
                .frame(width: 56, height: 56)
                .padding(.bottom, 18)
                .scaleEffect(isDropTargeted ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted)

            Text("Drop your app icon here")
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundColor(text)
                .padding(.bottom, 5)

            Text("PNG or JPEG · 1024 × 1024 source recommended\nGenerates all macOS icon sizes")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(text2)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.bottom, 22)

            Button(action: browseFiles) {
                Text("Browse files")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
                    .background(isBrowsePressed ? accentDark : (isBrowseHovered ? accentDark : accent))
                    .cornerRadius(6)
                    .scaleEffect(isBrowsePressed ? 0.97 : 1.0)
                    .animation(.easeInOut(duration: 0.14), value: isBrowseHovered)
                    .animation(.easeInOut(duration: 0.14), value: isBrowsePressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isBrowseHovered = $0 }
            .pressEvents { isBrowsePressed = true } onRelease: { isBrowsePressed = false }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 84)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDropTargeted || isDropHovered
                    ? accent.opacity(colorScheme == .dark ? 0.09 : 0.06)
                    : surfaceDown)
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted || isDropHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isDropTargeted || isDropHovered ? accent : borderUp,
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted || isDropHovered)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onHover { isDropHovered = $0 }
    }

    private var resultsPanel: some View {
        VStack(spacing: 0) {
            fileCard
            statusLine
            sizeGrid
            paddingControl
            downloadRow
            noteSection
        }
    }

    private var fileCard: some View {
        HStack(spacing: 13) {
            if let src = processor.sourceImage {
                Image(nsImage: src)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10).fill(surfaceDown).frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(processor.fileName)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(text).lineLimit(1)
                Text(processor.fileInfo)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { processor.reset() }) {
                Text("Change")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(text)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(isChangeHovered ? surface.opacity(0.9) : surfaceUp)
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(borderUp, lineWidth: 0.5))
                    .scaleEffect(isChangePressed ? 0.97 : 1.0)
                    .animation(.easeInOut(duration: 0.14), value: isChangeHovered)
                    .animation(.easeInOut(duration: 0.14), value: isChangePressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isChangeHovered = $0 }
            .pressEvents { isChangePressed = true } onRelease: { isChangePressed = false }
        }
        .padding(12)
        .background(surfaceUp)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderUp, lineWidth: 0.5))
        .padding(.bottom, 18)
    }

    private var statusLine: some View {
        Text(processor.isGenerating ? "Generating icon sizes…" : "All \(SIZES.count) sizes ready — choose your export:")
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundColor(text2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 13)
    }

    private var sizeGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(SIZES) { sizeCard($0) }
        }
        .padding(.bottom, 18)
    }

    private func sizeCard(_ sizeInfo: IconSize) -> some View {
        let isDone = processor.completedSizes.contains(sizeInfo.size)
        let dp = min(CGFloat(sizeInfo.size), 52)
        return VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(surfaceDown).frame(width: dp, height: dp)
                if let data = processor.generatedPNGs[sizeInfo.size], let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
                        .frame(width: dp, height: dp)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(.bottom, 7)
            Group {
                Text("\(sizeInfo.size)").font(.system(size: 12, weight: .semibold)).foregroundColor(text)
                + Text(" px").font(.system(size: 9, weight: .regular)).foregroundColor(text3)
            }
            .padding(.bottom, 2)
            Text(sizeInfo.role).font(.system(size: 8.5)).foregroundColor(text3).lineLimit(1).padding(.bottom, 3)
            Text(isDone ? "✓" : "…").font(.system(size: 10)).foregroundColor(isDone ? ok : text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10).padding(.horizontal, 6)
        .background(surfaceUp)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDone ? ok : borderUp, lineWidth: isDone ? 1.5 : 0.5))
        .background(RoundedRectangle(cornerRadius: 10).fill(isDone ? okDim : Color.clear))
    }

    private var paddingControl: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Toggle("macOS padding", isOn: $processor.usePadding)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12, weight: .medium)).foregroundColor(text)
                Slider(value: $processor.paddingPercent, in: 0...12, step: 0.5) { _ in
                    if processor.hasImage { processor.generate() }
                }
                .disabled(!processor.usePadding).frame(height: 4)
                Text(String(format: "%.1f%%", processor.paddingPercent))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(text).frame(minWidth: 36, alignment: .trailing)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(surfaceDown).cornerRadius(5)
            }
            Text("Insets the artwork so it fills ~88% of the tile — matches Apple's macOS icon template. Without this, an iOS-style source (edge-to-edge artwork) renders \"too big\" in Finder / Dock. Set to 0% to embed the source untouched.")
                .font(.system(size: 10.5)).foregroundColor(text3).lineSpacing(1.5).padding(.top, 2)
        }
        .padding(11)
        .background(surfaceUp).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderUp, lineWidth: 0.5))
        .padding(.bottom, 14)
    }

    private var downloadRow: some View {
        HStack(spacing: 8) {
            Button(action: saveICNS) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle").font(.system(size: 13))
                    Text("AppIcon.icns").font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 15).padding(.vertical, 7)
                .background(isIcnsPressed ? accentDark : (isIcnsHovered ? accentDark : accent))
                .cornerRadius(6)
                .scaleEffect(isIcnsPressed ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.14), value: isIcnsHovered)
                .animation(.easeInOut(duration: 0.14), value: isIcnsPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isIcnsHovered = $0 }
            .pressEvents { isIcnsPressed = true } onRelease: { isIcnsPressed = false }

            Button(action: saveZIP) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.zipper").font(.system(size: 13))
                    Text("Iconset ZIP").font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(text)
                .padding(.horizontal, 15).padding(.vertical, 7)
                .background(isZipHovered ? surface.opacity(0.9) : surfaceUp)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderUp, lineWidth: 0.5))
                .scaleEffect(isZipPressed ? 0.97 : 1.0)
                .animation(.easeInOut(duration: 0.14), value: isZipHovered)
                .animation(.easeInOut(duration: 0.14), value: isZipPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isZipHovered = $0 }
            .pressEvents { isZipPressed = true } onRelease: { isZipPressed = false }

            Spacer()
        }
        .padding(.bottom, 13)
    }

    private var noteSection: some View {
        noteText
            .font(.system(size: 11.5)).foregroundColor(text3).lineSpacing(1.65)
            .padding(10).background(surfaceDown).cornerRadius(6)
    }

    private var noteText: Text {
        let base: Text
        if processor.usePadding {
            base = Text("Artwork is inset by ") +
                   Text(String(format: "%.1f", processor.paddingPercent) + "%").bold() +
                   Text(" on every side (≈ ") +
                   Text(String(format: "%.0f", 100 - processor.paddingPercent * 2) + "% artwork").bold() +
                   Text(") to match the macOS icon template. ")
        } else {
            base = Text("No padding applied — source is embedded untouched (icons may look oversized in Finder). ")
        }
        return base +
            Text("AppIcon.icns").bold() +
            Text(" — drop directly into your Xcode project or app bundle Resources folder. ") +
            Text("Iconset ZIP").bold() +
            Text(" — unzip, then run ") +
            Text("iconutil -c icns AppIcon.iconset").font(.system(size: 10.5, design: .monospaced)) +
            Text(" in Terminal to produce an identical .icns.")
    }

    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            processor.loadImage(from: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async { self.processor.loadImage(from: url) }
                    }
                }
            }
        }
    }

    private func saveICNS() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppIcon.icns"
        panel.canCreateDirectories = true
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            guard let data = self.processor.buildICNS() else { return }
            try? data.write(to: url)
        }
    }

    private func saveZIP() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppIcon.iconset.zip"
        panel.allowedContentTypes = [.zip]
        panel.canCreateDirectories = true
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            guard let data = self.processor.buildZIP() else { return }
            try? data.write(to: url)
        }
    }
}

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct TrafficLightButton: View {
    let color: Color
    let icon: String
    @Binding var isHovered: Bool
    let showIcon: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Image(systemName: icon)
                    .font(.system(size: 7.5, weight: .black))
                    .foregroundColor(Color.black.opacity(0.55))
                    .frame(width: 12, height: 12)
                    .opacity(showIcon ? 1 : 0)
                    .animation(.easeInOut(duration: 0.12), value: showIcon)
            }
            .frame(width: 12, height: 12)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
        .frame(width: 12, height: 12)
    }
}

struct DropZoneIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let s = rect.width
        let scale = s / 56.0
        let r = CGRect(x: 7 * scale, y: 11 * scale, width: 42 * scale, height: 36 * scale)
        path.addRoundedRect(in: r, cornerSize: CGSize(width: 7 * scale, height: 7 * scale))
        path.move(to: CGPoint(x: 28 * scale, y: 21 * scale))
        path.addLine(to: CGPoint(x: 28 * scale, y: 37 * scale))
        path.move(to: CGPoint(x: 21 * scale, y: 30 * scale))
        path.addLine(to: CGPoint(x: 28 * scale, y: 37 * scale))
        path.addLine(to: CGPoint(x: 35 * scale, y: 30 * scale))
        return path
    }
}
