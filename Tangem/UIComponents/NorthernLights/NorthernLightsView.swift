import SwiftUI
import MetalKit

struct NorthernLightsView: UIViewRepresentable {
    let renderer: NorthernLightsRenderer
    let backgroundColor: Color
    let isPaused: Bool

    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> MTKView {
        let mtkView = DownscaledMTKView(frame: .zero, device: renderer.device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = renderer
        mtkView.autoResizeDrawable = false
        mtkView.preferredFramesPerSecond = 30
        mtkView.isPaused = isPaused

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        renderer.backgroundRGB = UIColor(backgroundColor).resolvedRGB(in: mtkView.traitCollection)
        renderer.updateColors(isDarkMode: colorScheme == .dark)
        mtkView.isPaused = isPaused
    }
}

private final class DownscaledMTKView: MTKView {
    static let renderScale: CGFloat = 0.5

    override func layoutSubviews() {
        super.layoutSubviews()

        let nativeScale = traitCollection.displayScale
        guard nativeScale > 0 else { return }

        // Fraction of the screen's native resolution, so the amount of upscaling is the same on @2x
        // and @3x screens.
        let drawableScale = nativeScale * Self.renderScale
        let size = CGSize(
            width: max(1, (bounds.width * drawableScale).rounded()),
            height: max(1, (bounds.height * drawableScale).rounded())
        )

        if drawableSize != size {
            drawableSize = size
        }
    }
}

private extension UIColor {
    func resolvedRGB(in traitCollection: UITraitCollection) -> RGB {
        let resolved = resolvedColor(with: traitCollection)
        guard
            let components = resolved.cgColor.components,
            let r = components[safe: 0],
            let g = components[safe: 1],
            let b = components[safe: 2]
        else {
            return .zero
        }

        return RGB(Float(r), Float(g), Float(b))
    }
}
