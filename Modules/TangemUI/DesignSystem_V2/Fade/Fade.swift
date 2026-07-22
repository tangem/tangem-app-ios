//
//  Fade.swift
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
public struct Fade: View {
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
        content
            .background(blurLayer)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        switch (variant, position) {
        case (.soft, .top):
            gradient(colors: [softColor, .clear])
        case (.soft, .bottom):
            gradient(colors: [.clear, softColor])
        case (.hard, .top):
            VStack(spacing: 0) {
                solidBlock
                gradient(colors: [opaqueColor, .clear])
            }
        case (.hard, .bottom):
            VStack(spacing: 0) {
                gradient(colors: [.clear, opaqueColor])
                solidBlock
            }
        }
    }

    private var solidBlock: some View {
        Rectangle()
            .fill(opaqueColor)
            .frame(height: Metrics.solidHeight)
    }

    private func gradient(colors: [Color]) -> some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .frame(maxHeight: .infinity)
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

    private var opaqueColor: Color {
        backgroundColor.opacity(Metrics.hardAlpha)
    }

    private var softColor: Color {
        backgroundColor.opacity(Metrics.softAlpha)
    }
}

// MARK: - Setupable

extension Fade: Setupable {
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

private extension Fade {
    enum Metrics {
        static let solidHeight: CGFloat = 56
        static let hardAlpha: Double = 0.95
        static let softAlpha: Double = 0.6
        static let blurRadius: CGFloat = 10
    }
}
