//
//  PolymarketOutcomeBubble.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct PolymarketOutcomeBubble: View {
    private let prefix: String?
    private let title: String
    private let style: PolymarketOutcomeStyle
    private let palette: Palette

    public init(prefix: String? = nil, title: String, style: PolymarketOutcomeStyle, palette: Palette = .outcome) {
        self.prefix = prefix
        self.title = title
        self.style = style
        self.palette = palette
    }

    public var body: some View {
        HStack(spacing: Constants.prefixSpacing) {
            if let prefix {
                Text(prefix)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: foregroundColor)
                .lineLimit(1)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(alignment: .topLeading) { tip }
        .accessibilityElement(children: .combine)
    }

    private var backgroundColor: Color {
        switch (palette, style) {
        case (.outcome, _): style.backgroundColor
        case (.bet, .affirmative): DesignSystem.Color.bgStatusSuccessSubtle
        case (.bet, .negative): DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    private var foregroundColor: Color {
        switch (palette, style) {
        case (.outcome, _): style.foregroundColor
        case (.bet, .affirmative): DesignSystem.Color.textStatusSuccess
        case (.bet, .negative): DesignSystem.Color.textStatusError
        }
    }

    private var tip: some View {
        Tip()
            .fill(backgroundColor)
            .frame(width: Constants.tipSide, height: Constants.tipSide)
            .offset(x: Constants.tipOffset, y: -Constants.tipSide)
    }
}

// MARK: - Palette

public extension PolymarketOutcomeBubble {
    enum Palette {
        case outcome
        case bet
    }
}

// MARK: - Tip

private struct Tip: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Constants

private extension PolymarketOutcomeBubble {
    enum Constants {
        static let cornerRadius: CGFloat = 12
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let tipSide: CGFloat = 8
        static let tipOffset: CGFloat = 16
        static let prefixSpacing: CGFloat = 4
    }
}
