//
//  TokenItemViewMiddleComponent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewMiddleComponent: View {
    let name: String
    let balance: LoadableTextView.State
    let hasPendingTransactions: Bool
    let hasError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: hasError ? Colors.Text.tertiary : Colors.Text.primary1
                    )
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if hasPendingTransactions {
                    Assets.pendingTxIndicator.image
                }
            }

            if !hasError {
                LoadableTextView(
                    state: balance,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    isSensitiveText: true
                )
            }
        }
    }
}
