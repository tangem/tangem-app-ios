//
//  TokenDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel

    var pendingTransactionViews: [PendingTxView] {
        let incTx = viewModel.incomingTransactions.map {
            PendingTxView(pendingTx: $0)
        }

        let outgTx = viewModel.outgoingTransactions.enumerated().map { (index, pendingTx) in
            PendingTxView(pendingTx: pendingTx) {
                viewModel.openPushTx(for: index)
            }
        }

        return incTx + outgTx
    }

    @ViewBuilder
    var exchangeCryptoButton: some View {
        if viewModel.canSellCrypto && viewModel.canBuyCrypto {
            TangemButton.vertical(title: "wallet_button_trade",
                                  systemImage: "arrow.up.arrow.down",
                                  action: viewModel.tradeCryptoAction)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                               isDisabled: !(viewModel.canBuyCrypto || viewModel.canSellCrypto)))
                .actionSheet(isPresented: $viewModel.showTradeSheet, content: {
                    ActionSheet(title: Text("wallet_choose_trade_action"),
                                buttons: [
                                    .default(Text("wallet_button_buy"), action: viewModel.openBuyCryptoIfPossible),
                                    .default(Text("wallet_button_sell"), action: viewModel.openSellCrypto),
                                    .cancel(),
                                ])
                })
        } else if viewModel.canSellCrypto {
            TangemButton.vertical(title: "wallet_button_sell",
                                  systemImage: "arrow.down",
                                  action: viewModel.openSellCrypto)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                               isDisabled: !viewModel.canSellCrypto))
        } else {
            // Keep the BUY button last so that it will appear when everything is disabled
            TangemButton.vertical(title: "wallet_button_buy",
                                  systemImage: "arrow.up",
                                  action: viewModel.openBuyCryptoIfPossible)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                               isDisabled: !viewModel.canBuyCrypto))
        }
    }

    @ViewBuilder var bottomButtons: some View {
        HStack(alignment: .center) {

            exchangeCryptoButton

            TangemButton(title: "wallet_button_send",
                         systemImage: "arrow.right",
                         action: viewModel.openSend)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                               isDisabled: !viewModel.canSend))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(viewModel.title)
                .font(Font.system(size: 36, weight: .bold, design: .default))
                .padding(.horizontal, 16)
                .animation(nil)

            if let subtitle = viewModel.tokenSubtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                    .animation(nil)
            }

            GeometryReader { geometry in
                RefreshableScrollView(onRefresh: { viewModel.onRefresh($0) }) {
                    VStack(spacing: 8.0) {
                        ForEach(self.pendingTransactionViews) { $0 }

                        if let walletModel = viewModel.walletModel {
                            BalanceAddressView(walletModel: walletModel,
                                               amountType: viewModel.amountType,
                                               isRefreshing: viewModel.isRefreshing,
                                               showExplorerURL: viewModel.showExplorerURL)
                        }

                        bottomButtons
                            .padding(.top, 16)


                        if let sendBlockedReason = viewModel.sendBlockedReason {
                            AlertCardView(title: "", message: sendBlockedReason)
                        }

                        if let existentialDepositWarning = viewModel.existentialDepositWarning {
                            AlertCardView(title: "common_warning".localized, message: existentialDepositWarning)
                        }

                        if let transactionLengthWarning = viewModel.transactionLengthWarning {
                            AlertCardView(title: "common_warning".localized, message: transactionLengthWarning)
                        }

                        if let solanaRentWarning = viewModel.solanaRentWarning {
                            AlertCardView(title: "common_warning".localized, message: solanaRentWarning)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .frame(width: geometry.size.width)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(false)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarItems(trailing: trailingButton)
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .ignoresKeyboard()
        .onAppear(perform: viewModel.onAppear)
        //        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        //            .filter {_ in !navigation.detailsToSend
        //                && !navigation.detailsToBuyCrypto && !navigation.detailsToSellCrypto
        //            }
        //            .delay(for: 0.5, scheduler: DispatchQueue.global())
        //            .receive(on: DispatchQueue.main)) { _ in
        //                viewModel.walletModel?.update(silent: true)
        //            }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    @ViewBuilder
    private var trailingButton: some View {
        Button(action: viewModel.onRemove) {
            Text("token_details_hide_token")
                .foregroundColor(.tangemGrayDark6)
                .font(.system(size: 17))
        }
        .animation(nil)
    }
}

struct TokenDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TokenDetailsView(viewModel: TokenDetailsViewModel(cardModel: PreviewCard.cardanoNote.cardModel,
                                                              blockchainNetwork: PreviewCard.cardanoNote.blockchainNetwork!,
                                                              amountType: .coin,
                                                              coordinator: TokenDetailsCoordinator()))
                .deviceForPreviewZoomed(.iPhone7)
        }
    }
}
