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
    let balanceCrypto: LoadableTextView.State
    let hasPendingTransactions: Bool
    let networkUnreachable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: networkUnreachable ? Colors.Text.tertiary : Colors.Text.primary1
                    )

                if hasPendingTransactions {
                    Assets.pendingTxIndicator.image
                }
            }

            if !networkUnreachable {
                LoadableTextView(
                    state: balanceCrypto,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    loaderTopPadding: 4
                )
            }
        }
        .lineLimit(2)
    }
}
