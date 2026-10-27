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
    let connectionTargetKind: WCTransactionConnectionTargetKind?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            connectionTargetRow

            WCTransactionNetworkRow(blockchain: .solana(curve: .ed25519_slip0010, testnet: false))
        }
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadius(14, corners: .allCorners)
    }

    @ViewBuilder
    private var connectionTargetRow: some View {
        if let connectionTargetKind {
            WCTransactionConnectionTargetRow(kind: connectionTargetKind)
            separator
        }
    }

    private var separator: some View {
        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
            .padding(.leading, 46)
            .padding(.trailing, 14)
    }
}
