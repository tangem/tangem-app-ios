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
            WCTransactionWalletRow(walletName: viewModel.userWalletName)
                .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))

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
        if let selectedFee = viewModel.selectedFee,
           let feeValue = selectedFee.value.value, let feeTokenItem = getFeeTokenItem() {
            WCTransactionFeeRowView(
                fee: feeValue,
                feeOption: selectedFee.option,
                blockchain: viewModel.transactionData.blockchain,
                feeTokenItem: feeTokenItem,
                onTap: {
                    viewModel.handleViewAction(.showFeeSelector)
                }
            )
        } else {
            HStack {
                Text("Network Fee")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer()

                if viewModel.selectedFee?.value.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Not available")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
            .frame(height: 44)
        }
    }

    private func getFeeTokenItem() -> TokenItem? {
        if let walletModel = viewModel.transactionData.userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain.networkId == viewModel.transactionData.blockchain.networkId
        }) {
            return walletModel.feeTokenItem
        }

        return nil
    }
}
