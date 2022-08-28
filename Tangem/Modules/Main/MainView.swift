//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk
import Combine
import MessageUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var sendChoiceButtons: [ActionSheet.Button] {
        let symbols = viewModel
            .wallets?
            .first?
            .amounts
            .filter { $0.key != .reserve && $0.value.value > 0 }
            .values
            .map { $0.self }

        let buttons = symbols?.map { amount in
            return ActionSheet.Button.default(Text(amount.currencySymbol)) {
                viewModel.openSend(for: Amount(with: amount, value: 0))
            }
        }
        return buttons ?? []
    }

    var pendingTransactionViews: [PendingTxView] {
        let incTx = viewModel.incomingTransactions.map {
            PendingTxView(pendingTx: $0)
        }

        let outgTx = viewModel.outgoingTransactions.enumerated().map { (index, pendingTx) -> PendingTxView in
            PendingTxView(pendingTx: pendingTx) {
                viewModel.openPushTx(for: index)
            }
        }

        return incTx + outgTx
    }

    var shouldShowBalanceView: Bool {
        if let walletModel = viewModel.cardModel.walletModels.first {
            switch walletModel.state {
            case .idle, .loading, .failed:
                return true
            default:
                return false
            }
        }

        return false
    }

    var noAccountView: MessageView? {
        if let walletModel = viewModel.cardModel.walletModels.first {
            switch walletModel.state {
            case .noAccount(let message):
                return MessageView(title: "wallet_error_no_account".localized, subtitle: message, type: .error)
            default:
                return nil
            }
        }

        return nil
    }

    var scanNavigationButton: some View {
        Button(action: viewModel.onScan,
               label: {
                   Image("wallets")
                       .foregroundColor(Color.black)
                       .frame(width: 44, height: 44)
                       .offset(x: -11, y: 0)
               })
               .buttonStyle(PlainButtonStyle())
    }

    var settingsNavigationButton: some View {
        Button(action: viewModel.openSettings,
               label: { Image("verticalDots")
                   .foregroundColor(Color.tangemGrayDark6)
                   .frame(width: 44.0, height: 44.0, alignment: .center)
                   .offset(x: 11, y: 0)
               })
               .accessibility(label: Text("voice_over_open_card_details"))
               .padding(0.0)
    }

    var backupWarningView: some View {
        BackUpWarningButton(tapAction: {
            viewModel.prepareForBackup()
        })
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    var singleWalletContent: some View {
        Group {
            ForEach(pendingTransactionViews) { $0 }
                .padding(.horizontal, 16.0)

            if viewModel.canShowAddress {
                if shouldShowBalanceView {
                    BalanceView(
                        balanceViewModel: viewModel.cardModel.walletModels.first!.balanceViewModel,
                        tokenViewModels: viewModel.cardModel.walletModels.first!.tokenViewModels
                    )
                    .padding(.horizontal, 16.0)
                } else if let noAccountView = noAccountView {
                    noAccountView
                }

                if let walletModel = viewModel.cardModel.walletModels.first {
                    AddressDetailView(showQr: $viewModel.showQR,
                                      selectedAddressIndex: $viewModel.selectedAddressIndex,
                                      showExplorerURL: $viewModel.showExplorerURL,
                                      walletModel: walletModel) {
                        viewModel.copyAddress()
                    }
                }
            } else {
                TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
    }

    @ViewBuilder
    var multiWalletContent: some View {
        Group {
            if !viewModel.tokenItemViewModels.isEmpty {
                TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            if let walletTokenListViewModel = viewModel.walletTokenListViewModel {
                WalletTokenListView(viewModel: walletTokenListViewModel)
            }

            AddTokensView(action: viewModel.openTokensList)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 6)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RefreshableScrollView(onRefresh: { viewModel.onRefresh($0) }) {
                    VStack(spacing: 8.0) {
                        CardView(image: viewModel.image,
                                 width: geometry.size.width - 32,
                                 cardSetLabel: viewModel.cardModel.cardSetLabel)
                            .fixedSize(horizontal: false, vertical: true)

                        if viewModel.isBackupAllowed {
                            backupWarningView
                        }

                        if viewModel.isShowNonDerivationButton {
                            Button(action: viewModel.deriveNonDerivedTokens) {
                                Text("DeriveNonDerivedTokens")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                            }
                        }

                        WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                            viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                        })
                        .padding(.horizontal, 16)


                        if viewModel.isMultiWalletMode {
                            multiWalletContent
                        } else {
                            singleWalletContent
                        }

                        Color.clear.frame(width: 10, height: 58, alignment: .center)
                    }
                }

                if !viewModel.isMultiWalletMode {
                    bottomButtons
                        .frame(width: geometry.size.width)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("wallet_title", displayMode: .inline)
        .navigationBarItems(leading: scanNavigationButton,
                            trailing: settingsNavigationButton)
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.onAppear()
        }
        .navigationBarHidden(false)
        .ignoresKeyboard()
        .alert(item: $viewModel.error) { $0.alert }
    }

    var sendButton: some View {
        TangemButton(title: "wallet_button_send",
                     systemImage: "arrow.right",
                     action: viewModel.sendTapped)
            .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                           isDisabled: !viewModel.canSend))
            .actionSheet(isPresented: $viewModel.showSelectWalletSheet) {
                ActionSheet(title: Text("wallet_choice_wallet_option_title"),
                            message: nil,
                            buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])

            }

    }

    @ViewBuilder
    var exchangeCryptoButton: some View {
        if viewModel.canSellCrypto {
            TangemButton.vertical(title: "wallet_button_trade",
                                  systemImage: "arrow.up.arrow.down",
                                  action: viewModel.tradeCryptoAction)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth))
                .actionSheet(isPresented: $viewModel.showTradeSheet, content: {
                    ActionSheet(title: Text("action_sheet_trade_hint"),
                                buttons: [
                                    .default(Text("wallet_button_topup"), action: viewModel.openBuyCryptoIfPossible),
                                    .default(Text("wallet_button_sell_crypto"), action: viewModel.openSellCrypto),
                                    .cancel(),
                                ])
                })
        } else {
            TangemButton.vertical(title: "wallet_button_topup",
                                  systemImage: "arrow.up",
                                  action: viewModel.openBuyCryptoIfPossible)
                .buttonStyle(TangemButtonStyle(layout: .flexibleWidth))
        }
    }


    var bottomButtons: some View {
        VStack {

            Spacer()

            VStack {
                HStack(alignment: .center) {
                    if viewModel.canBuyCrypto {
                        exchangeCryptoButton
                    }

                    if viewModel.canShowSend {
                        sendButton
                    }
                }
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(viewModel: .init(cardModel: PreviewCard.stellar.cardModel, coordinator: MainCoordinator()))
        }
        .previewGroup(devices: [.iPhone12ProMax])
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.locale, .init(identifier: "en"))
    }
}
