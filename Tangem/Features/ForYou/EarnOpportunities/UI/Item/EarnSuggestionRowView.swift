//
//  EarnSuggestionRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnSuggestionRowView: View {
    let data: EarnSuggestionRowData
    let onTap: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 40

    var body: some View {
        Row(
            title: data.name,
            subtitle: data.network,
            value: data.rateText,
            subvalue: data.productText
        )
        .start { icon }
        .portfolioTokenCard()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
    }
}

private extension EarnSuggestionRowView {
    var icon: some View {
        TokenIcon(
            tokenIconInfo: data.tokenIconInfo,
            size: CGSize(bothDimensions: iconSize),
            isWithOverlays: true,
            forceKingfisher: true
        )
    }
}
