//
//  ForYouAddFundsTokenSelectorView+RowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension ForYouAddFundsTokenSelectorView {
    struct RowView: View {
        let data: ForYouAddFundsTokenSelectorViewModel.RowData

        @ScaledMetric private var iconSize: CGFloat = 40

        var body: some View {
            Row(
                title: data.name,
                subtitle: data.network,
                value: data.fiat,
                subvalue: data.crypto
            )
            .start { icon }
            .contentShape(Rectangle())
            .onTapGesture(perform: data.onTap)
            .accessibilityAddTraits(.isButton)
        }
    }
}

private extension ForYouAddFundsTokenSelectorView.RowView {
    var icon: some View {
        TokenIcon(
            tokenIconInfo: data.tokenIconInfo,
            size: CGSize(bothDimensions: iconSize)
        )
    }
}
