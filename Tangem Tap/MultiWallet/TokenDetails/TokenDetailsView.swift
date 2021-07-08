//
//  TokenDetailsView.swift
//  Tangem Tap
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
    
    private var buyCryptoButtonInfo: HorizontalButtonStack.ButtonInfo {
        .init(imageName: "arrow.up",
              title: "wallet_button_topup",
              action: { viewModel.buyCryptoAction() },
              isDisabled: !viewModel.canBuyCrypto)
    }
    private var sellCryptoButtonInfo: HorizontalButtonStack.ButtonInfo {
        .init(imageName: "arrow.down",
              title: "wallet_button_sell_crypto",
              action: { viewModel.sellCryptoAction() },
              isDisabled: !viewModel.canSellCrypto || !viewModel.canSend)
    }
    
    private var sendButtonInfo: HorizontalButtonStack.ButtonInfo {
        .init(imageName: "arrow.right",
              title: "wallet_button_send",
              action: viewModel.sendButtonAction,
              isDisabled: !viewModel.canSend)
    }
    private var bottomButtonsInfo: [HorizontalButtonStack.ButtonInfo] {
        var buttons = [HorizontalButtonStack.ButtonInfo]()
        
        buttons.append(buyCryptoButtonInfo)
        
        if viewModel.canSellCrypto {
            buttons.append(sellCryptoButtonInfo)
        }
        
        buttons.append(sendButtonInfo)
        return buttons
    }
    
    var navigationLinks: some View {
        Group {
            NavigationLink(destination: WebViewContainer(url: viewModel.buyCryptoUrl,
//                                                         closeUrl: viewModel.topupCloseUrl,
                                                         title: "wallet_button_topup",
                                                         addLoadingIndicator: true,
                                                         urlActions: [
                                                            viewModel.buyCryptoCloseUrl: { _ in
                                                                navigation.detailsToBuyCrypto = false
                                                                viewModel.sendAnalyticsEvent(.userBoughtCrypto)
                                                            }
                                                         ]),
                           isActive: $navigation.detailsToBuyCrypto)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.sellCryptoUrl,
                                                         title: "wallet_button_sell_crypto",
                                                         addLoadingIndicator: true,
                                                         urlActions: [
                                                            viewModel.sellCryptoRequestUrl: { response in
                                                                viewModel.processSellCryptoRequest(response)
                                                            }
                                                         ]),
                           isActive: $navigation.detailsToSellCrypto)
            
            //https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279
            // Weird IOS 14.5/XCode 12.5 bug. Navigation link cause an immediate pop, if there are exactly 2 links presented
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder var bottomButtons: some View {
        HStack(alignment: .center) {
            HorizontalButtonStack(buttons: bottomButtonsInfo)
        }
        .sheet(isPresented: $navigation.detailsToSend) {
            if let sellCryptoRequest = viewModel.sellCryptoRequest {
                SendView(viewModel: viewModel.assembly.makeSellCryptoSendViewModel(
                            with: Amount(with: viewModel.blockchain, value: sellCryptoRequest.amount),
                            destination: sellCryptoRequest.targetAddress,
                            blockchain: viewModel.blockchain,
                            card: viewModel.card), onSuccess: {})
                    .environmentObject(navigation)
            } else if let amountToSend = viewModel.amountToSend {
                SendView(viewModel: viewModel.assembly.makeSendViewModel(
                            with: amountToSend,
                            blockchain: viewModel.blockchain,
                            card: viewModel.card), onSuccess: {})
                    .environmentObject(navigation)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            navigationLinks
            
            Text(viewModel.title)
                .font(Font.system(size: 36, weight: .bold, design: .default))
            if let subtitle = viewModel.tokenSubtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark)
                    .padding(.bottom, 8)
            }
            
            
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 8.0) {
                        ForEach(self.pendingTransactionViews) { $0 }
                            .sheet(item: $viewModel.txIndexToPush) { index in
                                if let tx = viewModel.transactionToPush {
                                    PushTxView(viewModel: viewModel.assembly.makePushViewModel(for: tx,
                                                                                               blockchain: viewModel.blockchain,
                                                                                               card: viewModel.card),
                                               onSuccess: {})
                                        .environmentObject(navigation)
                                }
                            }
                        
                        if let walletModel = viewModel.walletModel {
                            BalanceAddressView(walletModel: walletModel, amountType: viewModel.amountType)
                                .frame(width: geometry.size.width)
                            
                        }
                        
                        bottomButtons
                            .padding(.top, 16)
                        
                        
                        if viewModel.shouldShowTxNote {
                            AlertCardView(title: "", message: viewModel.txNoteMessage)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16.0)
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.onRemove()
            }
            
        }, label: { Text("wallet_remove_token")
            .foregroundColor(viewModel.canDelete ? Color.tangemTapGrayDark6 : Color.tangemTapGrayLight5)
        })
        .disabled(!viewModel.canDelete)
        )
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .ignoresKeyboard()
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .filter {_ in !navigation.detailsToSend
                        && !navigation.detailsToBuyCrypto && !navigation.detailsToSellCrypto
                    }
                    .delay(for: 0.5, scheduler: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)) { _ in
            viewModel.walletModel?.update(silent: true)
        }
    }
}

struct TokenDetailsView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly(for: .ethereum)
    
    static var previews: some View {
        NavigationView {
            TokenDetailsView(viewModel: assembly.makeTokenDetailsViewModel(blockchain: assembly.previewBlockchain))
                .environmentObject(assembly.services.navigationCoordinator)
        }
        .deviceForPreviewZoomed(.iPhone7)
    }
}
