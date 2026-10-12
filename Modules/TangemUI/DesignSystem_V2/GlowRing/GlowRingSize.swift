//
//  GlowRingSize.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

/// Figma `Size` prop: `card` hugs a rounded container and takes its radius from the caller;
/// `fullscreen` hugs the device bezel with a thicker, softer layer stack and falls back to the
/// screen's radius when the caller does not know the container's own.
public enum GlowRingSize: Sendable, Hashable {
    case card(cornerRadius: CGFloat = 24)
    case fullscreen(cornerRadius: CGFloat?)
}

extension GlowRingSize {
    typealias BorderLayer = GlowRingModifier.Config.BorderLayer

    var cornerRadius: CGFloat {
        switch self {
        case .card(let cornerRadius): cornerRadius
        case .fullscreen(let cornerRadius): cornerRadius ?? Self.screenRadius
        }
    }

    /// Blur on the top layer is 1 rather than Figma's 0.5 — a half-point blur reads as no blur
    /// at all through `GraphicsContext`, and 1 is what the component shipped with.
    var layers: [BorderLayer] {
        switch self {
        case .card:
            [
                BorderLayer(stroke: 2, blur: 1),
                BorderLayer(stroke: 4, blur: 8),
                BorderLayer(stroke: 4, blur: 16),
            ]
        case .fullscreen:
            [
                BorderLayer(stroke: 2, blur: 1),
                BorderLayer(stroke: 2, blur: 16),
                BorderLayer(stroke: 8, blur: 32),
            ]
        }
    }
}

private extension GlowRingSize {
    /// Figma `screen-radius`. The home-button devices have square displays, where a rounded ring
    /// would carve corners out of the screen — the threshold separates them (SE 2/3 and the 8 are
    /// 667 pt tall, the 8 Plus 736; the next family up starts at 812).
    static var screenRadius: CGFloat {
        UIScreen.main.bounds.height < compactHeightThreshold ? 0 : 55
    }

    static let compactHeightThreshold: CGFloat = 780
}
