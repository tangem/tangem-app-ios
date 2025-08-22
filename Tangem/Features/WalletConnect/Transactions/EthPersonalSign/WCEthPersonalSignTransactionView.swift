//
//  WCEthPersonalSignTransactionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI
import TangemAssets

struct WCEthPersonalSignTransactionView: View {
    let walletName: String
    let isWalletRowVisible: Bool
    let blockchain: Blockchain
    let addressRowViewModel: WCTransactionAddressRowViewModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isWalletRowVisible {
                WCTransactionWalletRow(walletName: walletName)
                separator
            }

            WCTransactionNetworkRow(blockchain: blockchain)
            addressRowView
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    @ViewBuilder
    private var addressRowView: some View {
        if let addressRowViewModel {
            separator
            WCTransactionAddressRowView(viewModel: addressRowViewModel)
        }
    }

    private var separator: some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .padding(.leading, 46)
            .padding(.trailing, 14)
    }
}
