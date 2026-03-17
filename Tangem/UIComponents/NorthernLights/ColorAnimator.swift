import Foundation
import simd

// MARK: - Color wrappers

typealias RGB = SIMD3<Float>

@inline(__always)
private func rgb(hex: UInt32) -> RGB {
    let r = Float((hex >> 16) & 0xFF) / 255
    let g = Float((hex >> 8) & 0xFF) / 255
    let b = Float(hex & 0xFF) / 255
    return .init(r, g, b)
}

@inline(__always)
private func lerp(_ a: RGB, _ b: RGB, _ t: Float) -> RGB {
    simd_mix(a, b, RGB(repeating: t))
}

// MARK: - Interpolation

/// Evaluate cubic-bezier(0.4, 0.0, 0.2, 1.0) — FastOutSlowInEasing.
/// Uses Newton-Raphson iteration to invert the X curve.
private func fastOutSlowIn(_ t: Float) -> Float {
    cubicBezier(x1: 0.4, y1: 0.0, x2: 0.2, y2: 1.0, t: t)
}

private func cubicBezier(x1: Float, y1: Float, x2: Float, y2: Float, t: Float) -> Float {
    if t <= 0 { return 0 }
    if t >= 1 { return 1 }

    // Find the parameter `s` such that bezierX(s) == t via Newton's method
    var s = t
    for _ in 0 ..< 8 {
        let x = bezierComponent(a: x1, b: x2, t: s) - t
        let dx = bezierDerivative(a: x1, b: x2, t: s)
        if abs(dx) < 1e-6 { break }
        s -= x / dx
    }
    s = max(0, min(1, s))
    return bezierComponent(a: y1, b: y2, t: s)
}

private func bezierComponent(a: Float, b: Float, t: Float) -> Float {
    let s = 1 - t
    return 3 * s * s * t * a + 3 * s * t * t * b + t * t * t
}

private func bezierDerivative(a: Float, b: Float, t: Float) -> Float {
    let s = 1 - t
    return 3 * s * s * a + 6 * s * t * (b - a) + 3 * t * t * (1 - b)
}

// MARK: - Keyframe Track

/// A single color track that cycles through 4 keyframes over 16 seconds
/// with a staggered start offset (matching Android's StartOffset.Delay).
struct KeyframeTrack {
    let keyframes: [RGB] // 4 keyframes
    let offsetSeconds: Float // stagger offset in seconds

    init(hexColors: [UInt32], offsetSeconds: Float) {
        keyframes = hexColors.map { rgb(hex: $0) }
        self.offsetSeconds = offsetSeconds
    }

    /// Evaluate the track color at a given absolute time (seconds).
    func evaluate(at time: Float) -> RGB {
        let cycleDuration: Float = 40.0
        let segmentDuration: Float = 10.0

        // Apply offset: the track's own phase is delayed by offsetSeconds
        let trackTime = fmod(time + cycleDuration - offsetSeconds, cycleDuration)

        // Which segment [0..3] and local fraction [0..1]
        let segmentIndex = Int(trackTime / segmentDuration) % 4
        let fraction = (trackTime - Float(segmentIndex) * segmentDuration) / segmentDuration
        let eased = fastOutSlowIn(fraction)

        let fromColor = keyframes[segmentIndex]
        let toColor = keyframes[(segmentIndex + 1) % 4]
        return lerp(fromColor, toColor, eased)
    }
}

// MARK: - Color Keyframes

enum NorthernLightsColors {
    static let track1Dark = KeyframeTrack(hexColors: [0xFF0D0D3A, 0xFF141455, 0xFF1C1C6E, 0xFF111148], offsetSeconds: 0)
    static let track1Light = KeyframeTrack(hexColors: [0xFFCCB8EE, 0xFFBBA0E8, 0xFFCCB0F0, 0xFFC4AAEC], offsetSeconds: 0)

    static let track2Dark = KeyframeTrack(hexColors: [0xFF0A1238, 0xFF0D1D55, 0xFF112266, 0xFF0E1A4A], offsetSeconds: 10)
    static let track2Light = KeyframeTrack(hexColors: [0xFFB8C8F0, 0xFF9AAEE8, 0xFFAABEF0, 0xFFA0B8EE], offsetSeconds: 10)

    static let track3Dark = KeyframeTrack(hexColors: [0xFF110A38, 0xFF1C1050, 0xFF2A1666, 0xFF180E48], offsetSeconds: 20)
    static let track3Light = KeyframeTrack(hexColors: [0xFFDDC8F5, 0xFFCCB0EE, 0xFFD8BEF5, 0xFFD0B8F2], offsetSeconds: 20)

    static let track4Dark = KeyframeTrack(hexColors: [0xFF081A30, 0xFF0D2844, 0xFF113355, 0xFF0D2240], offsetSeconds: 5)
    static let track4Light = KeyframeTrack(hexColors: [0xFFB8C4EE, 0xFFA8B4E8, 0xFFB4C0EE, 0xFFAABCEC], offsetSeconds: 5)
}

// MARK: - Uniforms struct

struct Uniforms {
    var uTime: Float = 0
    var uResolution: SIMD2<Float> = .zero
    var uColor0: SIMD3<Float> = .zero
    var uColor1: SIMD3<Float> = .zero
    var uColor2: SIMD3<Float> = .zero
    var uColor3: SIMD3<Float> = .zero
    var uColor4: SIMD3<Float> = .zero
}
