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

    /// Evaluate the track color at a given absolute time (seconds).
    func evaluate(at time: Float) -> RGB {
        let cycleDuration: Float = 16.0
        let segmentDuration: Float = 4.0

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
    /// Track 1: indigo → bright blue → lavender → hot violet
    static let track1 = KeyframeTrack(
        keyframes: [rgb(hex: 0x2A1480), rgb(hex: 0x4477EE), rgb(hex: 0xBBAAEE), rgb(hex: 0x8833EE)],
        offsetSeconds: 0
    )

    /// Track 2: dark blue → cyan-blue → sky → teal
    static let track2 = KeyframeTrack(
        keyframes: [rgb(hex: 0x1444AA), rgb(hex: 0x22AADD), rgb(hex: 0x99BBDD), rgb(hex: 0x44DDCC)],
        offsetSeconds: 4
    )

    /// Track 3: dark purple → medium purple → rose pink → magenta
    static let track3 = KeyframeTrack(
        keyframes: [rgb(hex: 0x4422BB), rgb(hex: 0x7733CC), rgb(hex: 0xDD88BB), rgb(hex: 0xEE44AA)],
        offsetSeconds: 8
    )

    /// Track 4: dark violet → medium violet → light pink → hot pink
    static let track4 = KeyframeTrack(
        keyframes: [rgb(hex: 0x331199), rgb(hex: 0x6644CC), rgb(hex: 0xCC77DD), rgb(hex: 0xFF66CC)],
        offsetSeconds: 2
    )
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
