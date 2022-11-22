//
//  SingleWalletContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletContentView: View {
    @ObservedObject private var viewModel: SingleWalletContentViewModel

    init(viewModel: SingleWalletContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            ForEach(viewModel.pendingTransactionViews) { $0 }
                .padding(.horizontal, 16.0)

            if viewModel.canShowAddress {
                walletView

                if let walletModel = viewModel.singleWalletModel {
                    AddressDetailView(selectedAddressIndex: $viewModel.selectedAddressIndex,
                                      walletModel: walletModel,
                                      copyAddress: viewModel.copyAddress,
                                      showQr: viewModel.openQR,
                                      showExplorerURL: viewModel.showExplorerURL(url:))
                }

            } else {
                TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
    }

    @ViewBuilder
    private var walletView: some View {
        if let singleWalletModel = viewModel.singleWalletModel {
            switch singleWalletModel.state {
            case .created, .noDerivation:
                EmptyView()

            case .idle, .loading, .failed:
                BalanceView(
                    balanceViewModel: singleWalletModel.balanceViewModel(),
                    tokenBalanceViewModels: singleWalletModel.tokenBalanceViewModels()
                )
                .padding(.horizontal, 16.0)

            case .noAccount(let message):
                MessageView(title: "wallet_error_no_account".localized, subtitle: message, type: .error)
            }
        }
    }
}
