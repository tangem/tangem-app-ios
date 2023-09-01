//
//  TokenItemViewTrailingComponent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewTrailingComponent: View {
    let hasError: Bool
    let errorMessage: String?
    let balanceFiat: LoadableTextView.State
    let priceChangeState: TokenPriceChangeView.State

    var body: some View {
        VStack(alignment: .trailing) {
            if hasError, let errorMessage {
                Text(errorMessage)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            } else {
                LoadableTextView(
                    state: balanceFiat,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 4
                )

                TokenPriceChangeView(state: priceChangeState)
            }
        }
    }
}
