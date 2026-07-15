//
//  TangemFade.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI
import TangemAssets
import TangemUIUtils

/// Design-system v2 fade overlay for the top or bottom edge of scrollable content.
///
/// [Figma]([REDACTED_INFO]
public struct TangemFade: View {
    public enum Position: Hashable, Sendable, CaseIterable {
        case top
        case bottom
    }

    public enum Variant: Hashable, Sendable, CaseIterable {
        case hard
        case soft
    }

    private let position: Position
    private var variant: Variant = .soft
    private var isBlurEnabled = false
    private var backgroundColor: Color = DesignSystem.Color.bgPrimary

    public init(position: Position) {
        self.position = position
    }

    public var body: some View {
        Rectangle()
            .fill(tintGradient)
            .background(blurLayer)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.height)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var blurLayer: some View {
        if isBlurEnabled {
            VariableBlur(direction: blurDirection)
                .maximumBlurRadius(Metrics.blurRadius)
                .dimmingTintColor(nil)
                .dimmingAlpha(.constant(alpha: 0))
                .dimmingOvershoot(nil)
        }
    }

    private var blurDirection: VariableBlur.Direction {
        switch position {
        case .top: .down
        case .bottom: .up
        }
    }

    private var tintGradient: LinearGradient {
        let opaque = backgroundColor.opacity(Metrics.hardAlpha)
        let soft = backgroundColor.opacity(Metrics.softAlpha)
        let transparent = Color.clear

        let stops: [Gradient.Stop] = switch (variant, position) {
        case (.hard, .top):
            [
                .init(color: opaque, location: 0),
                .init(color: opaque, location: Metrics.solidRatio),
                .init(color: transparent, location: 1),
            ]
        case (.hard, .bottom):
            [
                .init(color: transparent, location: 0),
                .init(color: opaque, location: 1 - Metrics.solidRatio),
                .init(color: opaque, location: 1),
            ]
        case (.soft, .top):
            [
                .init(color: soft, location: 0),
                .init(color: transparent, location: 1),
            ]
        case (.soft, .bottom):
            [
                .init(color: transparent, location: 0),
                .init(color: soft, location: 1),
            ]
        }

        return LinearGradient(gradient: Gradient(stops: stops), startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Setupable

extension TangemFade: Setupable {
    public func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }

    public func blurred(_ isEnabled: Bool = true) -> Self {
        map { $0.isBlurEnabled = isEnabled }
    }

    public func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }
}

// MARK: - Metrics

private extension TangemFade {
    enum Metrics {
        static let height: CGFloat = 96
        static let solidRatio: CGFloat = 40.0 / height
        static let hardAlpha: Double = 0.95
        static let softAlpha: Double = 0.6
        static let blurRadius: CGFloat = 10
    }
}
