//
//  PolymarketOutcomeBubble.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct PolymarketOutcomeBubble: View {
    let title: String
    let style: PolymarketOutcomeStyle

    var body: some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: style.foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .fill(style.backgroundColor)
            )
            .overlay(alignment: .topLeading) { tip }
            .accessibilityElement(children: .combine)
    }

    private var tip: some View {
        Tip()
            .fill(style.backgroundColor)
            .frame(width: Constants.tipSide, height: Constants.tipSide)
            .offset(x: Constants.tipOffset, y: -Constants.tipSide)
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
    }
}
