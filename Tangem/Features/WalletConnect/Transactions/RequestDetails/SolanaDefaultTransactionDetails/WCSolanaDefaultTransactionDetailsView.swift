//
//  WCSolanaDefaultTransactionDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI
import TangemAssets

struct WCSolanaDefaultTransactionDetailsView: View {
    let walletName: String
    let isWalletRowVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isWalletRowVisible {
                WCTransactionWalletRow(walletName: walletName)

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.leading, 46)
                    .padding(.trailing, 14)
            }

            WCTransactionNetworkRow(blockchain: .solana(curve: .ed25519_slip0010, testnet: false))
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }
}
