//
//  TokenItemViewTrailingComponent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewTrailingComponent: View {
    let networkUnreachable: Bool
    let balanceFiat: LoadableTextView.State
    let changePercentage: LoadableTextView.State

    var body: some View {
        VStack(alignment: .trailing) {
            if networkUnreachable {
                Text(Localization.commonUnreachable)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            } else {
                LoadableTextView(
                    state: balanceFiat,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 4
                )

                LoadableTextView(
                    state: changePercentage,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 6
                )
            }
        }
    }
}
