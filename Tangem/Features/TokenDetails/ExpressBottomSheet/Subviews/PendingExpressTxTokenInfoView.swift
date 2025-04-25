//
//  PendingExpressTxTokenInfoView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PendingExpressTxTokenInfoView: View {
    let tokenIconInfo: TokenIconInfo
    let amountText: String
    let fiatAmountTextState: LoadableTextView.State
    let iconSize: CGSize = .init(bothDimensions: 36)

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                SensitiveText(amountText)
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                if fiatAmountTextState != .noData {
                    LoadableTextView(
                        state: fiatAmountTextState,
                        font: Fonts.Regular.caption1,
                        textColor: Colors.Text.tertiary,
                        loaderSize: .init(width: 52, height: 12),
                        isSensitiveText: true
                    )
                }
            }
        }
    }
}
