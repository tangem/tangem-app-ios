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
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var pendingTransactionViews: [PendingTxView] {
        let incTx = viewModel.incomingTransactions.map {
            PendingTxView(pendingTx: $0)
        }
        
        let outgTx = viewModel.outgoingTransactions.enumerated().map { (index, pendingTx) in
            PendingTxView(pendingTx: pendingTx) {
                viewModel.pushOutgoingTx(at: index)
            }
        }
        
        return incTx + outgTx
    }
    
    var navigationLinks: some View {
        Group {
            NavigationLink(destination: WebViewContainer(viewModel: .init(url: viewModel.buyCryptoUrl,
                                                         //                                                         closeUrl: viewModel.topupCloseUrl,
                                                         title: "wallet_button_topup".localized,
                                                         addLoadingIndicator: true,
                                                         urlActions: [
                                                            viewModel.buyCryptoCloseUrl: { _ in
                                                                navigation.detailsToBuyCrypto = false
                                                                viewModel.sendAnalyticsEvent(.userBoughtCrypto)
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                                    viewModel.walletModel?.update(silent: true)
                                                                }
                                                            }
                                                         ])),
                           isActive: $navigation.detailsToBuyCrypto)
            
            NavigationLink(destination: WebViewContainer(viewModel: .init(url: viewModel.sellCryptoUrl,
                                                         title: "wallet_button_sell_crypto".localized,
                                                         addLoadingIndicator: true,
                                                         urlActions: [
                                                            viewModel.sellCryptoRequestUrl: { response in
                                                                viewModel.processSellCryptoRequest(response)
                                                            }
                                                         ])),
                           isActive: $navigation.detailsToSellCrypto)
            
            //https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279
            // Weird IOS 14.5/XCode 12.5 bug. Navigation link cause an immediate pop, if there are exactly 2 links presented
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    var exchangeCryptoButton: some View {
        if viewModel.canSellCrypto && viewModel.canBuyCrypto {
            TangemButton.vertical(title: "wallet_button_trade",
                                  systemImage: "arrow.up.arrow.down",
                                  action: viewModel.tradeCryptoAction)
            .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                           isDisabled: !(viewModel.canBuyCrypto || viewModel.canSellCrypto)))
            .actionSheet(isPresented: $navigation.detailsToTradeSheet, content: {
                ActionSheet(title: Text("action_sheet_trade_hint"),
                            buttons: [
                                .default(Text("wallet_button_topup"), action: viewModel.buyCryptoAction),
                                .default(Text("wallet_button_sell_crypto"), action: viewModel.sellCryptoAction),
                                .cancel()
                            ])
            })
        } else if viewModel.canSellCrypto {
            TangemButton.vertical(title: "wallet_button_sell_crypto",
                                  systemImage: "arrow.down",
                                  action: viewModel.sellCryptoAction)
            .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                           isDisabled: !viewModel.canSellCrypto))
        } else {
            // Keep the BUY button last so that it will appear when everything is disabled
            TangemButton.vertical(title: "wallet_button_topup",
                                  systemImage: "arrow.up",
                                  action: viewModel.buyCryptoAction)
            .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                           isDisabled: !viewModel.canBuyCrypto))
        }
    }
    
    @ViewBuilder var bottomButtons: some View {
        HStack(alignment: .center) {
            
            exchangeCryptoButton
            
            TangemButton(title: "wallet_button_send",
                         systemImage: "arrow.right",
                         action: viewModel.sendButtonAction)
            .buttonStyle(TangemButtonStyle(layout: .flexibleWidth,
                                           isDisabled: !viewModel.canSend))
        }
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            
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
                                                   showExplorerURL: $viewModel.showExplorerURL)
                            }
                            
                            bottomButtons
                                .padding(.top, 16)
                            
                            
                            if let sendBlockedReason = viewModel.sendBlockedReason {
                                AlertCardView(title: "", message: sendBlockedReason)
                            }
                            
                            if let unsupportedTokenWarning = viewModel.unsupportedTokenWarning {
                                AlertCardView(title: "common_warning".localized, message: unsupportedTokenWarning)
                            }
                            
                            if let solanaRentWarning = viewModel.solanaRentWarning {
                                AlertCardView(title: "common_warning".localized, message: solanaRentWarning)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(width: geometry.size.width)
                    }
                }
            }
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .sheet(item: $viewModel.showExplorerURL) {
                    WebViewContainer(viewModel: .init(url: $0, title: "common_explorer_format".localized(viewModel.blockchainNetwork.blockchain.displayName), withCloseButton: true))
                }
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .sheet(item: $viewModel.txIndexToPush) { index in
                    if let tx = viewModel.transactionToPush {
                        PushTxView(viewModel: viewModel.assembly.makePushViewModel(for: tx,
                                                                                   blockchainNetwork: viewModel.blockchainNetwork,
                                                                                   card: viewModel.card),
                                   onSuccess: {})
                        .environmentObject(navigation)
                    }
                }
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .sheet(isPresented: $navigation.detailsToSend) {
                    if let sellCryptoRequest = viewModel.sellCryptoRequest {
                        SendView(viewModel: viewModel.assembly.makeSellCryptoSendViewModel(
                            with: Amount(with: viewModel.blockchainNetwork.blockchain, value: sellCryptoRequest.amount),
                            destination: sellCryptoRequest.targetAddress,
                            blockchainNetwork: viewModel.blockchainNetwork,
                            card: viewModel.card))
                        .environmentObject(navigation)
                    } else if let amountToSend = viewModel.amountToSend {
                        SendView(viewModel: viewModel.assembly.makeSendViewModel(
                            with: amountToSend,
                            blockchainNetwork: viewModel.blockchainNetwork,
                            card: viewModel.card))
                        .environmentObject(navigation)
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
        .onReceive(viewModel.dismissalRequestPublisher, perform: {
            presentationMode.wrappedValue.dismiss()
        })
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
    
    private var trailingButton: some View {
        Button(action: viewModel.onRemove) {
            Text("wallet_remove_token")
                .foregroundColor(.tangemGrayDark6)
                .font(.system(size: 17))
        }
    }
}

struct TokenDetailsView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly(for: .cardanoNote)
    static let navigation = NavigationCoordinator()
    
    static var previews: some View {
        NavigationView {
            TokenDetailsView(viewModel: assembly.makeTokenDetailsViewModel(blockchainNetwork: assembly.previewBlockchainNetwork))
                .environmentObject(navigation)
        }
        .deviceForPreviewZoomed(.iPhone7)
    }
}
