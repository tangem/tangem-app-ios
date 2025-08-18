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
                    .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))
            }

            WCTransactionNetworkRow(blockchain: blockchain)
                .padding(.init(top: isWalletRowVisible ? 0 : 12, leading: 16, bottom: 12, trailing: 16))

            addressRowView
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    @ViewBuilder
    private var addressRowView: some View {
        if let addressRowViewModel {
            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.leading, 46)
                .padding(.trailing, 14)

            WCTransactionAddressRowView(viewModel: addressRowViewModel)
        }
    }
}
