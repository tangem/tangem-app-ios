//
//  PolymarketActivitySectionHeader.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketActivitySectionHeader: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
            .padding(.bottom, Constants.bottomPadding)
    }
}

// MARK: - Constants

private extension PolymarketActivitySectionHeader {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 24
        static let bottomPadding: CGFloat = 12
    }
}
