//
//  PolymarketOutcomePill.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct PolymarketOutcomePill: View {
    private let title: String
    private let style: PolymarketOutcomeStyle

    public init(title: String, style: PolymarketOutcomeStyle) {
        self.title = title
        self.style = style
    }

    public var body: some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: style.foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, Constants.horizontalPadding)
            .frame(minHeight: Constants.minHeight)
            .background(style.backgroundColor, in: Capsule())
    }
}

// MARK: - Constants

private extension PolymarketOutcomePill {
    enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let minHeight: CGFloat = 24
    }
}
