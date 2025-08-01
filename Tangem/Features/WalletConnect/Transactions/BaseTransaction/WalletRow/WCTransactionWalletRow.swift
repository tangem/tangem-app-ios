//
//  WCTransactionWalletRon.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct WCTransactionWalletRow: View {
    let walletName: String

    var body: some View {
        HStack(spacing: 0) {
            Assets.Glyphs.walletNew.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)
            Text(Localization.wcCommonWallet)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .padding(.trailing, 8)

            Spacer()

            Text(walletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
        }
        .lineLimit(1)
    }
}
