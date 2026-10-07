//
//  SwapSummarySlippageView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SwapSummarySlippageView: View {
    var body: some View {
        BaseOneLineRow(
            icon: nil,
            // [REDACTED_TODO_COMMENT]
            title: "Slippage",
            trailingView: {
                Text("Auto")
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        )
        .shouldShowTrailingIcon(false)
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }
}
