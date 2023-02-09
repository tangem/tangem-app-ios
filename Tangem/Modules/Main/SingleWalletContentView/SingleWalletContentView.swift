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
                    AddressDetailView(
                        selectedAddressIndex: $viewModel.selectedAddressIndex,
                        walletModel: walletModel,
                        copyAddress: viewModel.copyAddress,
                        showQr: viewModel.openQR,
                        showExplorerURL: viewModel.showExplorerURL(url:)
                    )
                }

            } else {
                VStack(alignment: .leading, spacing: 12) {
                    TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                        .padding([.horizontal, .top], 16)
                        .padding(.bottom, viewModel.buttons.isEmpty ? 16 : 0)

                    if !viewModel.buttons.isEmpty {
                        HStack {
                            ForEach(viewModel.buttons) { buttonInfo in
                                MainButton(
                                    title: buttonInfo.title,
                                    icon: .leading(buttonInfo.icon),
                                    style: .secondary,
                                    dimensions: .init(
                                        maxWidth: .infinity,
                                        verticalPadding: 8,
                                        horizontalPadding: 14,
                                        cornerRadius: 10,
                                        iconToLabelSpacing: 8,
                                        iconSize: .init(width: 16, height: 16)
                                    ),
                                    font: Fonts.Bold.subheadline,
                                    isLoading: buttonInfo.isLoading,
                                    isDisabled: buttonInfo.isDisabled,
                                    action: buttonInfo.action
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 19)
                    }
                }
                .background(Colors.Background.primary)
                .cornerRadius(16)
                .padding(.horizontal, 16)
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
                MessageView(title: Localization.walletErrorNoAccount, subtitle: message, type: .error)
            }
        }
    }
}
