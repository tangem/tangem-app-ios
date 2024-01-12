//
//  ExpressCurrencyBottomView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpressCurrencyBottomView: View {
    let fiatState: LoadableTextView.State
    let priceChangePercent: String?

    let tokenState: LoadableTextView.State

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                LoadableTextView(
                    state: fiatState,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 70, height: 12),
                    lineLimit: 1,
                    isSensitiveText: false
                )

                if let priceChangePercent = priceChangePercent {
                    HStack(spacing: 4) {
                        Text("(\(priceChangePercent))")
                            .style(Fonts.Regular.footnote, color: Colors.Text.attention)

                        Assets.attention.image
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
            }

            Spacer()

            LoadableTextView(
                state: tokenState,
                font: Fonts.Bold.footnote,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 30, height: 14),
                lineLimit: 1,
                isSensitiveText: false
            )
        }
    }
}

extension ExpressCurrencyBottomView {
    enum State {
        case notAvailable
        case fiat(LoadableTextView.State)
    }
}
