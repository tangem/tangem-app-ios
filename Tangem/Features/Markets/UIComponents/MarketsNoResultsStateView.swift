//
//  MarketsNoResultsStateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MarketsNoResultsStateView: View {
    var body: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSearchNoResultsLabel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Layout.defaultHorizontalInset)
    }
}

extension MarketsNoResultsStateView {
    enum Layout {
        static let defaultHorizontalInset = 16.0
    }
}
