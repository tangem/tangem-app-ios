//
//  WCRequiredNetworksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WCRequiredNetworksView: View {
    let blockchainNames: [String]

    var body: some View {
        if blockchainNames.isNotEmpty {
            HStack(alignment: .top, spacing: 12) {
                Assets.WalletConnect.yellowWarningCircle.image
                VStack(alignment: .leading, spacing: 8) {
                    Text("The wallet has no required networks")
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text("Add the \(blockchainNames.joined(separator: ", ")) to your portfolio for this wallet. Add these networks to your wallet.")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .multilineTextAlignment(.leading)
            }
        }
    }
}
