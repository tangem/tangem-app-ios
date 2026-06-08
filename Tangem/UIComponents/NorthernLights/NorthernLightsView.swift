import SwiftUI
import MetalKit

struct NorthernLightsView: UIViewRepresentable {
    let backgroundColor: Color

    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice(),
              let renderer = try? NorthernLightsRenderer(device: device) else {
            assertionFailure("Failed to initialize Metal for NorthernLightsView")
            return MTKView()
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = renderer
        mtkView.contentScaleFactor = 0.5
        mtkView.preferredFramesPerSecond = 30

        context.coordinator.renderer = renderer

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.backgroundRGB = UIColor(backgroundColor).resolvedRGB(in: mtkView.traitCollection)
        context.coordinator.renderer?.updateColors(isDarkMode: colorScheme == .dark)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var renderer: NorthernLightsRenderer?
    }
}

final class NorthernLightsRenderer: NSObject, MTKViewDelegate {
    var backgroundRGB: RGB = .zero

    private var color1: KeyframeTrack = NorthernLightsColors.track1Dark
    private var color2: KeyframeTrack = NorthernLightsColors.track2Dark
    private var color3: KeyframeTrack = NorthernLightsColors.track3Dark
    private var color4: KeyframeTrack = NorthernLightsColors.track4Dark

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    private var startTime = CACurrentMediaTime()

    init(device: MTLDevice) throws {
        guard let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "northernLightsVertex"),
              let fragmentFunction = library.makeFunction(name: "northernLightsFragment") else {
            throw MetalInitializationError.resourceCreationFailed
        }

        self.commandQueue = commandQueue

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }

        let elapsed = Float(CACurrentMediaTime() - startTime)

        var uniforms = Uniforms(
            uTime: elapsed,
            uResolution: SIMD2(Float(view.bounds.width), Float(view.bounds.height)),
            uColor0: color1.evaluate(at: elapsed),
            uColor1: color2.evaluate(at: elapsed),
            uColor2: color3.evaluate(at: elapsed),
            uColor3: color4.evaluate(at: elapsed),
            uColor4: backgroundRGB
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func updateColors(isDarkMode: Bool) {
        color1 = isDarkMode ? NorthernLightsColors.track1Dark : NorthernLightsColors.track1Light
        color2 = isDarkMode ? NorthernLightsColors.track2Dark : NorthernLightsColors.track2Light
        color3 = isDarkMode ? NorthernLightsColors.track3Dark : NorthernLightsColors.track3Light
        color4 = isDarkMode ? NorthernLightsColors.track4Dark : NorthernLightsColors.track4Light
    }
}

extension NorthernLightsRenderer {
    enum MetalInitializationError: Error {
        case resourceCreationFailed
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
