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
            MainButton(
                title: Localization.walletButtonTrade,
                icon: .leading(Assets.exchangeMini),
                isDisabled: !(viewModel.canBuyCrypto || viewModel.canSellCrypto),
                action: viewModel.tradeCryptoAction
            )
            .actionSheet(isPresented: $viewModel.showTradeSheet, content: {
                ActionSheet(title: Text(Localization.walletChooseTradeAction),
                            buttons: [
                                .default(Text(Localization.walletButtonBuy), action: viewModel.openBuyCryptoIfPossible),
                                .default(Text(Localization.walletButtonSell), action: viewModel.openSellCrypto),
                                .cancel(),
                            ])
            })
        } else if viewModel.canSellCrypto {
            MainButton(
                title: Localization.walletButtonSell,
                icon: .leading(Assets.arrowDownMini),
                isDisabled: !viewModel.canSellCrypto,
                action: viewModel.openSellCrypto
            )
        } else {
            // Keep the BUY button last so that it will appear when everything is disabled
            MainButton(
                title: Localization.walletButtonBuy,
                icon: .leading(Assets.arrowUpMini),
                isDisabled: !viewModel.canBuyCrypto,
                action: viewModel.openBuyCryptoIfPossible
            )
        }
    }

    @ViewBuilder var bottomButtons: some View {
        HStack(alignment: .center) {
            if FeatureProvider.isAvailable(.exchange) {
                exchangeButton
            } else {
                exchangeCryptoButton
            }

            MainButton(
                title: Localization.walletButtonSend,
                icon: .leading(Assets.arrowRightMini),
                isDisabled: !viewModel.canSend,
                action: viewModel.openSend
            )
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
                            AlertCardView(title: Localization.commonWarning, message: existentialDepositWarning)
                        }

                        if let transactionLengthWarning = viewModel.transactionLengthWarning {
                            AlertCardView(title: Localization.commonWarning, message: transactionLengthWarning)
                        }

                        if let solanaRentWarning = viewModel.solanaRentWarning {
                            AlertCardView(title: Localization.commonWarning, message: solanaRentWarning)
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
            Text(Localization.tokenDetailsHideToken)
                .foregroundColor(.tangemGrayDark6)
                .font(.system(size: 17))
        }
        .animation(nil)
    }

    @ViewBuilder
    var exchangeButton: some View {
        switch viewModel.exchangeButtonState {
        case .single(let option):
            MainButton(
                title: option.title,
                icon: .leading(option.icon),
                isDisabled: !viewModel.isAvailable(type: option)
            ) {
                viewModel.didTapExchangeButtonAction(type: option)
            }

        case .multi:
            MainButton(
                title: Localization.walletButtonActions,
                icon: .leading(Assets.exchangeIcon),
                action: viewModel.openExchangeActionSheet
            )
            .actionSheet(item: $viewModel.exchangeActionSheet, content: { $0.sheet })

        }
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
