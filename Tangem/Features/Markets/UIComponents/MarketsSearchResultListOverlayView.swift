//
//  MarketsSearchResultListOverlayView.swift
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

struct MarketsSearchResultListOverlayView: View {
    @Binding var titleOpacity: CGFloat
    @Binding var totalHeight: CGFloat

    var body: some View {
        Text(Localization.marketsSearchResultTitle)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .opacity(titleOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Layout.listOverlayTopInset)
            .padding(.horizontal, Layout.defaultHorizontalInset)
            .readGeometry(\.size.height, bindTo: $totalHeight)
    }
}

extension MarketsSearchResultListOverlayView {
    enum Layout {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 10.0
    }
}
