//
//  WCEthTransactionDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemUI
import TangemAssets

struct WCEthTransactionDetailsView: View {
    @ObservedObject var viewModel: WCTransactionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isWalletRowVisible {
                WCTransactionWalletRow(walletName: viewModel.userWalletName)
                    .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))
            }

            WCTransactionNetworkRow(blockchain: viewModel.transactionData.blockchain)
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.init(top: 0, leading: 16, bottom: 10, trailing: 16))

            feeRow
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    @ViewBuilder
    private var feeRow: some View {
        if let feeRowViewModel = viewModel.feeRowViewModel {
            WCFeeRowView(viewModel: feeRowViewModel)
                .onTapGesture(perform: feeRowViewModel.onTap)
        }
    }
}
