import SwiftUI
import MetalKit

struct NorthernLightsView: UIViewRepresentable {
    let backgroundColor: Color

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice(),
              let renderer = try? NorthernLightsRenderer(device: device) else {
            assertionFailure("Failed to initialize Metal for NorthernLightsView")
            return MTKView()
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.renderer?.backgroundRGB = backgroundColor.toRGB() ?? .zero
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var renderer: NorthernLightsRenderer?
    }
}

final class NorthernLightsRenderer: NSObject, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    var backgroundRGB: RGB = .zero
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
            uColor0: NorthernLightsColors.track1.evaluate(at: elapsed),
            uColor1: NorthernLightsColors.track2.evaluate(at: elapsed),
            uColor2: NorthernLightsColors.track3.evaluate(at: elapsed),
            uColor3: NorthernLightsColors.track4.evaluate(at: elapsed),
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
}

extension NorthernLightsRenderer {
    enum MetalInitializationError: Error {
        case resourceCreationFailed
    }
}

private extension Color {
    func toRGB() -> RGB? {
        guard
            let components = UIColor(self).cgColor.components,
            let r = components[safe: 0],
            let g = components[safe: 1],
            let b = components[safe: 2]
        else {
            return nil
        }

        return RGB(Float(r), Float(g), Float(b))
    }
}
