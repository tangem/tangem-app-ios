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
import TangemAccessibilityIdentifiers

struct SwapSummarySlippageView: View {
    @ObservedObject var viewModel: SwapSummarySlippageViewModel
    let tapAction: () -> Void

    var body: some View {
        Group {
            if viewModel.isEditable {
                SwiftUI.Button(action: tapAction) { content }
            } else {
                content
            }
        }
        .accessibilityIdentifier(SwapAccessibilityIdentifiers.slippageBlock)
    }

    private var content: some View {
        BaseOneLineRow(
            icon: nil,
            // [REDACTED_TODO_COMMENT]
            title: "Slippage",
            trailingView: {
                Text(valueText)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        )
        .shouldShowTrailingIcon(viewModel.isEditable)
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }

    private var valueText: String {
        switch viewModel.value {
        case .auto: "Auto"
        case .custom(let text): text
        }
    }
}
