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

public struct PolymarketOutcomePill<Accessory: View>: View {
    private let title: String
    private let style: PolymarketOutcomeStyle
    private let accessory: Accessory

    public init(title: String, style: PolymarketOutcomeStyle, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.style = style
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: Constants.accessorySpacing) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: style.foregroundColor)
                .lineLimit(1)

            accessory
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.minHeight)
        .background(style.backgroundColor, in: Capsule())
    }
}

public extension PolymarketOutcomePill where Accessory == EmptyView {
    init(title: String, style: PolymarketOutcomeStyle) {
        self.init(title: title, style: style) { EmptyView() }
    }
}

// MARK: - Constants

private enum Constants {
    static let accessorySpacing: CGFloat = 4
    static let horizontalPadding: CGFloat = 8
    static let minHeight: CGFloat = 24
}
