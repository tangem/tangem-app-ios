import SwiftUI
import MetalKit

struct NorthernLightsView: UIViewRepresentable {
    let renderer: NorthernLightsRenderer
    let backgroundColor: Color
    let isPaused: Bool

    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: renderer.device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = renderer
        mtkView.contentScaleFactor = 0.5
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
