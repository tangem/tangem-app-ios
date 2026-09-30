//
//  LineRevealAnimation.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Phase

/// 0 — text hidden, 1 — text in place, 2 — text gone.
enum LineRevealPhase {
    static let hidden: Double = 0
    static let visible: Double = 1
    static let gone: Double = 2
}

// MARK: - Timing

struct LineRevealTiming {
    // Enter
    var enterDuration: TimeInterval = 1.1
    var lineDuration: TimeInterval = 0.8
    var lineStagger: TimeInterval = 0.12
    var enterDistance: CGFloat = 8
    var enterBlur: CGFloat = 0

    // Exit
    var exitDuration: TimeInterval = 0.4
    var exitLineDuration: TimeInterval = 0.3
    var exitLineStagger: TimeInterval = 0.03
    var exitDistance: CGFloat = 10
    var exitBlur: CGFloat = 6
}

// MARK: - Curve

enum LineRevealCurve {
    struct State {
        var opacity: Double
        /// Vertical offset, pt (positive — down, negative — up).
        var offset: CGFloat
        var blur: CGFloat
    }

    static func state(
        phase: Double,
        lineIndex: Int,
        lineCount: Int,
        timing: LineRevealTiming,
        reduceMotion: Bool
    ) -> State {
        if phase <= LineRevealPhase.visible {
            let local = localProgress(
                time: phase * timing.enterDuration,
                index: lineIndex,
                count: lineCount,
                total: timing.enterDuration,
                lineDuration: timing.lineDuration,
                maxStagger: timing.lineStagger
            )
            let fade = easeOutCubic(min(1, local / 0.55))

            if reduceMotion {
                return State(opacity: fade, offset: 0, blur: 0)
            }

            return State(
                opacity: fade,
                offset: timing.enterDistance * CGFloat(1 - easeOutQuart(local)),
                blur: timing.enterBlur * CGFloat(1 - easeOutCubic(local))
            )
        } else {
            let local = localProgress(
                time: (phase - LineRevealPhase.visible) * timing.exitDuration,
                index: lineIndex,
                count: lineCount,
                total: timing.exitDuration,
                lineDuration: timing.exitLineDuration,
                maxStagger: timing.exitLineStagger
            )
            let eased = easeInCubic(local)

            if reduceMotion {
                return State(opacity: 1 - eased, offset: 0, blur: 0)
            }

            return State(
                opacity: 1 - eased,
                offset: -timing.exitDistance * CGFloat(eased),
                blur: timing.exitBlur * CGFloat(eased)
            )
        }
    }

    private static func localProgress(
        time: Double,
        index: Int,
        count: Int,
        total: Double,
        lineDuration: Double,
        maxStagger: Double
    ) -> Double {
        let stagger = count > 1
            ? min(maxStagger, max(0, total - lineDuration) / Double(count - 1))
            : 0
        let start = Double(index) * stagger
        return min(max((time - start) / lineDuration, 0), 1)
    }

    private static func easeOutQuart(_ x: Double) -> Double { 1 - pow(1 - x, 4) }
    private static func easeOutCubic(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    private static func easeInCubic(_ x: Double) -> Double { x * x * x }
}

// MARK: - Renderer (iOS 18+)

@available(iOS 18.0, *)
struct LineRevealRenderer: TextRenderer {
    var phase: Double
    let timing: LineRevealTiming
    let reduceMotion: Bool

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    /// Vertical only: horizontal insets would widen the text layout past the frame and break wrapping.
    var displayPadding: EdgeInsets {
        let top = max(timing.exitDistance + timing.exitBlur, timing.enterBlur) + 4
        return EdgeInsets(top: top, leading: 0, bottom: timing.enterDistance + timing.enterBlur, trailing: 0)
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lineCount = layout.count

        for (index, line) in layout.enumerated() {
            let state = LineRevealCurve.state(
                phase: phase,
                lineIndex: index,
                lineCount: lineCount,
                timing: timing,
                reduceMotion: reduceMotion
            )
            guard state.opacity > 0.001 else { continue }

            var lineContext = context
            lineContext.opacity *= state.opacity

            if state.blur > 0.01 {
                lineContext.addFilter(.blur(radius: state.blur))
            }

            lineContext.translateBy(x: 0, y: state.offset)
            lineContext.draw(line)
        }
    }
}

// MARK: - Fallback (iOS 17 and below)

private struct LineRevealFallbackModifier: ViewModifier, Animatable {
    var phase: Double
    let timing: LineRevealTiming
    let reduceMotion: Bool

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        let state = LineRevealCurve.state(
            phase: phase,
            lineIndex: 0,
            lineCount: 1,
            timing: timing,
            reduceMotion: reduceMotion
        )

        content
            .opacity(state.opacity)
            .blur(radius: state.blur)
            .offset(y: state.offset)
    }
}

// MARK: - View extension

extension View {
    @ViewBuilder
    func lineReveal(phase: Double, timing: LineRevealTiming, reduceMotion: Bool) -> some View {
        if #available(iOS 18.0, *) {
            textRenderer(LineRevealRenderer(phase: phase, timing: timing, reduceMotion: reduceMotion))
        } else {
            modifier(LineRevealFallbackModifier(phase: phase, timing: timing, reduceMotion: reduceMotion))
        }
    }
}
