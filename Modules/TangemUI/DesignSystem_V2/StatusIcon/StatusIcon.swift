//
//  StatusIcon.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Lottie
import SwiftUI
import TangemAssets
import TangemUIUtils

/// Design-system v2 draw-on animated status glyph, played from the DS-Core Lottie assets.
///
/// [Figma]([REDACTED_INFO]
///
/// Pick the picture with ``Glyph``; everything else has a DS default and is overridable
/// via the chain modifiers: ``tint(_:)`` (defaults to the glyph's status color),
/// ``size(_:)`` (defaults to 40 pt), ``glow(_:)`` (the blurred duplicate behind the
/// glyph), and ``animated(_:)`` — `false` freezes the final frame. The animation plays
/// once per appearance; with Reduce Motion enabled the final frame is shown immediately.
/// Timings and easing live in the Lottie assets and are deliberately not exposed.
///
/// ```swift
/// StatusIcon(.checkmark)
///
/// StatusIcon(.warning)
///     .tint(DesignSystem.Color.iconAccent)
///     .size(28)
///     .glow(false)
/// ```
public struct StatusIcon: View, Setupable {
    public enum Glyph: Sendable, Hashable, CaseIterable {
        case info
        case checkmark
        case heartBroken
        case warning
    }

    private let glyph: Glyph
    var tint: Color?
    var isGlowEnabled = true
    var isAnimated = true
    var startDelay: TimeInterval = 0

    @State private var isPlaybackStarted = false
    @ScaledMetric var side: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    public init(_ glyph: Glyph) {
        self.glyph = glyph
        _side = ScaledMetric(wrappedValue: Metrics.defaultSide)
    }

    public var body: some View {
        ZStack {
            if isGlowEnabled {
                animationView
                    .blur(radius: Metrics.glowBlurRadius)
                    .opacity(Metrics.glowOpacity)
            }

            animationView
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
        .task {
            guard startDelay > 0, isAnimated, !reduceMotion else { return }

            try? await Task.sleep(for: .seconds(startDelay))
            isPlaybackStarted = true
        }
    }

    private var animationView: some View {
        LottieView(animation: glyph.animation)
            .playbackMode(playbackMode)
            .configuration(LottieConfiguration(renderingEngine: .mainThread))
            .animationSpeed(Metrics.playbackSpeed)
            .configure { animationView in
                animationView.setValueProvider(
                    ColorValueProvider(resolvedTint),
                    keypath: AnimationKeypath(keypath: Metrics.colorKeypath)
                )
            }
            .resizable()
    }

    private var playbackMode: LottiePlaybackMode {
        if !isAnimated || reduceMotion {
            .paused(at: .progress(1))
        } else if startDelay > 0, !isPlaybackStarted {
            .paused(at: .progress(0))
        } else {
            .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
        }
    }

    private var resolvedTint: LottieColor {
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let resolved = UIColor(tint ?? glyph.defaultTint).resolvedColor(with: traits)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return LottieColor(r: red, g: green, b: blue, a: alpha)
    }
}

// MARK: - Scaled side access

extension StatusIcon {
    /// A property wrapper's backing storage is always `private`, so the `size(_:)`
    /// modifier in the sibling file goes through this same-file setter.
    func updatingScaledSide(_ side: CGFloat) -> Self {
        map { $0._side = ScaledMetric(wrappedValue: side) }
    }
}

// MARK: - Glyph defaults

private extension StatusIcon.Glyph {
    var animation: LottieAnimation {
        switch self {
        case .info: LottieFile.lottieStatusScreenInfo
        case .checkmark: LottieFile.lottieStatusScreenCheckmark
        case .heartBroken: LottieFile.lottieStatusScreenHeart
        case .warning: LottieFile.lottieStatusScreenWarning
        }
    }

    var defaultTint: Color {
        switch self {
        case .info: DesignSystem.Color.iconStatusInfo
        case .checkmark: DesignSystem.Color.iconStatusSuccess
        case .heartBroken: DesignSystem.Color.iconStatusError
        case .warning: DesignSystem.Color.iconStatusWarning
        }
    }
}

// MARK: - Metrics

private extension StatusIcon {
    enum Metrics {
        static let defaultSide: CGFloat = 40
        static let glowBlurRadius: CGFloat = 8
        static let glowOpacity: Double = 0.4
        /// The assets run their active part in ~0.8 s while the Figma preview settles the
        /// glyph by ~0.6 s — compress playback so the endpoints match. Requires the
        /// main-thread rendering engine: the Core Animation engine silently ignores
        /// `animationSpeed` in this Lottie version.
        static let playbackSpeed: Double = 0.8 / 0.6
        /// The DS-Core Lottie assets ship with black strokes/fills on purpose —
        /// the color is supplied at runtime through this catch-all keypath.
        static let colorKeypath = "**.Color"
    }
}
