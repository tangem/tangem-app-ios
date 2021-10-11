//
//  MainView.swift
//  Tangem Tap
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
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
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
                viewModel.amountToSend = Amount(with: amount, value: 0)
                viewModel.showSendScreen()
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
                viewModel.pushOutgoingTx(at: index)
            }
        }
        
        return incTx + outgTx
    }
    
    var isUnsupportdState: Bool {
        switch viewModel.state {
        case .unsupported, .notScannedYet:
            return true
        default:
            return false
        }
    }
    
    var shouldShowEmptyView: Bool {
        if let cardModel = viewModel.state.cardModel {
            switch cardModel.state {
            case .empty, .created:
                return true
            default:
                if cardModel.isTwinCard {
                    if cardModel.isNotPairedTwin && !cardModel.hasBalance {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }
    
    var shouldShowBalanceView: Bool {
        if let walletModel = viewModel.cardModel?.walletModels?.first {
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
        if let walletModel = viewModel.cardModel?.walletModels?.first {
            switch walletModel.state {
            case .noAccount(let message):
                return MessageView(title: "wallet_error_no_account".localized, subtitle: message, type: .error)
            default:
                return nil
            }
        }
        
        return nil
    }
    
    @ViewBuilder var scanButton: some View {
        let scanAction = {
            withAnimation {
                viewModel.scan()
            }
        }
        
        if viewModel.canBuyCrypto && !viewModel.canCreateWallet ||
            ((viewModel.cardModel?.isNotPairedTwin ?? false)
                && (viewModel.cardModel?.hasBalance ?? false)) {
            if  (viewModel.cardModel?.isMultiWallet ?? false) {
                TangemButton(title: "wallet_button_scan",
                             image: "scan",
                             action: scanAction)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   isLoading: viewModel.isScanning))
            } else {
                TangemButton.vertical(title: "wallet_button_scan",
                                     image: "scan",
                                     action: scanAction)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   isLoading: viewModel.isScanning))
            }
        } else {
            TangemButton(title: "wallet_button_scan",
                         image: "scan",
                         action: scanAction)
                .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                               isLoading: viewModel.isScanning))
        }
    }
    
    var createWalletButton: some View {
        TangemButton(title: viewModel.isTwinCard ? "wallet_button_create_twin_wallet" : "wallet_button_create_wallet",
                     systemImage: "arrow.right") { viewModel.createWallet()  }
            .buttonStyle(TangemButtonStyle(layout: .big,
                                           isDisabled: !viewModel.canCreateWallet || !viewModel.canCreateTwinWallet,
                                           isLoading: viewModel.isCreatingWallet))
    }
    
    @ViewBuilder var sendButton: some View {
        let action = { viewModel.sendTapped() }
        
        if viewModel.canBuyCrypto {
            TangemButton.vertical(title: "wallet_button_send",
                                  systemImage: "arrow.right",
                                  action: action)
                .buttonStyle(TangemButtonStyle(isDisabled: !viewModel.canSend))
        } else {
            TangemButton(title: "wallet_button_send",
                         systemImage: "arrow.right") { action() }
                .buttonStyle(TangemButtonStyle(layout: .big, isDisabled: !viewModel.canSend))
        }
    }
    
    @ViewBuilder
    var exchangeCryptoButton: some View {
        if viewModel.canSellCrypto {
            TangemButton.vertical(title: "wallet_button_trade",
                                 systemImage: "arrow.up.down.wide") {
                navigation.mainToTradeSheet = true
            }
            .buttonStyle(TangemButtonStyle())
            .actionSheet(isPresented: $navigation.mainToTradeSheet, content: {
                ActionSheet(title: Text("action_sheet_trade_hint"),
                            buttons: [
                                .default(Text("wallet_button_topup"), action: {
                                    viewModel.buyCryptoAction()
                                }),
                                .default(Text("wallet_button_sell_crypto"), action: {
                                    viewModel.sellCryptoAction()
                                }),
                                .cancel()
                            ])
            })
        } else {
            TangemButton.vertical(title: "wallet_button_topup",
                                 systemImage: "arrow.up",
                                 action: viewModel.buyCryptoAction)
            .buttonStyle(TangemButtonStyle())
        }
    }
    
    var navigationLinks: some View {
        VStack {
            NavigationLink(destination: DetailsView(viewModel: viewModel.assembly.makeDetailsViewModel()),
                           isActive: $viewModel.navigation.mainToSettings)
            
            NavigationLink(destination: TokenDetailsView(viewModel: viewModel.assembly.makeTokenDetailsViewModel(blockchain: viewModel.selectedWallet.blockchain,
                                                                                                                 amountType: viewModel.selectedWallet.amountType)),
                           isActive: $navigation.mainToTokenDetails)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.buyCryptoURL,
                                                         title: "wallet_button_topup",
                                                         addLoadingIndicator: true,
                                                         urlActions: [ viewModel.buyCryptoCloseUrl : { _ in
                                                            navigation.mainToBuyCrypto = false
                                                            viewModel.sendAnalyticsEvent(.userBoughtCrypto)
                                                         }
                                                         ]),
                           isActive: $navigation.mainToBuyCrypto)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.sellCryptoURL,
                                                         title: "wallet_button_sell_crypto",
                                                         addLoadingIndicator: true,
                                                         urlActions: [ viewModel.sellCryptoCloseUrl : { request in
                                                            viewModel.extractSellCryptoRequest(from: request)
                                                         }
                                                         ]),
                           isActive: $navigation.mainToSellCrypto)
            
            
//            NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardOnboardingViewModel(isFromMain: true)),
//                           isActive: $navigation.mainToTwinOnboarding)
            
//            NavigationLink(destination: CardOnboardingView(viewModel: viewModel.assembly.getCardOnboardingViewModel()),
//                           isActive: $navigation.mainToCardOnboarding)
        }
    }
    
    //prevent navbar glitches
    var isNavBarHidden: Bool {
//        if navigation.mainToTwinsWalletWarning || navigation.mainToTwinOnboarding {
//            return true //hide navbar when navigate to onboarding/warning
//        }
        
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationLinks
            GeometryReader { geometry in
                VStack {
                    RefreshableScrollView(refreshing: $viewModel.isRefreshing) {
                        VStack(spacing: 8.0) {
                            CardView(image: viewModel.image,
                                     width: geometry.size.width - 32,
                                     currentCardNumber: viewModel.cardNumber)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if isUnsupportdState {
                                MessageView(title: "wallet_error_unsupported_blockchain".localized, subtitle: "wallet_error_unsupported_blockchain_subtitle".localized, type: .error)
                            } else {
                                WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                                    viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                                })
                                .padding(.horizontal, 16)
                                
                                if !viewModel.cardModel!.isMultiWallet {
                                    ForEach(pendingTransactionViews) { $0 }
                                        .padding(.horizontal, 16.0)
                                        .sheet(item: $viewModel.txIndexToPush) { index in
                                            if let tx = viewModel.transactionToPush,
                                               let blockchain = viewModel.cardModel?.walletModels?.first?.wallet.blockchain,
                                               let cardModel = viewModel.cardModel {
                                                PushTxView(viewModel: viewModel.assembly.makePushViewModel(for: tx,
                                                                                                           blockchain: blockchain,
                                                                                                           card: cardModel),
                                                           onSuccess: {})
                                                    .environmentObject(navigation)
                                            }
                                        }
                                }
                                
                                if shouldShowEmptyView {
                                    MessageView(
                                        title: viewModel.isTwinCard ? "wallet_error_empty_twin_card".localized : "wallet_error_empty_card".localized,
                                        subtitle: viewModel.isTwinCard ? "wallet_error_empty_twin_card_subtitle".localized : "wallet_error_empty_card_subtitle".localized,
                                        type: .error
                                    )
                                } else {
                                    if viewModel.cardModel!.isMultiWallet {
                                        ForEach(viewModel.tokenItemViewModels) { item in
                                            TokensListItemView(item: item)
                                                .onTapGesture {
                                                    viewModel.onWalletTap(item)
                                                }
                                        }
                                        .padding(.horizontal, 16)
                                        
                                        AddTokensView(action: {
                                            navigation.mainToAddTokens = true
                                        })
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                        .sheet(isPresented: $navigation.mainToAddTokens, content: {
                                            AddNewTokensView(viewModel: viewModel.assembly.makeAddTokensViewModel(for: viewModel.cardModel!))
                                                .environmentObject(navigation)
                                        })
                                        
                                    } else {
                                        if shouldShowBalanceView {
                                            BalanceView(
                                                balanceViewModel: viewModel.cardModel!.walletModels!.first!.balanceViewModel,
                                                tokenViewModels: viewModel.cardModel!.walletModels!.first!.tokenViewModels
                                            )
                                            .padding(.horizontal, 16.0)
                                        } else {
                                            if noAccountView != nil {
                                                noAccountView!
                                            } else {
                                                EmptyView()
                                            }
                                        }
                                        
                                        if let walletModel = viewModel.cardModel?.walletModels?.first,
                                           let card = viewModel.cardModel?.cardInfo.card  {
                                            if card.isTwinCard, viewModel.cardModel?.cardInfo.twinCardInfo?.pairPublicKey == nil {
                                                EmptyView()
                                            } else {
                                                AddressDetailView(showCreatePayID: $navigation.mainToCreatePayID,
                                                                  showQr: $navigation.mainToQR,
                                                                  selectedAddressIndex: $viewModel.selectedAddressIndex,
                                                                  walletModel: walletModel,
                                                                  payID: viewModel.cardModel!.payId)
                                            }
                                        }
                                        
                                        //                                Color.clear.frame(width: 1, height: 1, alignment: .center)
                                        //                                    .sheet(isPresented: $navigation.mainToCreatePayID, content: {
                                        //                                        CreatePayIdView(cardId: viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
                                        //                                                        cardViewModel: viewModel.state.cardModel!)
                                        //                                    })
                                    }
                                }
                            }
                        }
                    }
                    
                    bottomButtons
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8.0)
                        .frame(width: geometry.size.width)
                }
            }
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .sheet(item: $viewModel.emailFeedbackCase) { emailCase -> MailView in
                    let dataCollector: EmailDataCollector
                    switch emailCase {
                    case .negativeFeedback:
                        dataCollector = viewModel.negativeFeedbackDataCollector
                    case .scanTroubleshooting:
                        dataCollector = viewModel.failedCardScanTracker
                    }
                    return MailView(dataCollector: dataCollector, support: .tangem, emailType: emailCase.emailType)
                }
            ScanTroubleshootingView(isPresented: $navigation.mainToTroubleshootingScan) {
                viewModel.scan()
            } requestSupportAction: {
                viewModel.failedCardScanTracker.resetCounter()
                viewModel.emailFeedbackCase = .scanTroubleshooting
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(navigation.mainToSettings || navigation.mainToBuyCrypto || navigation.mainToTokenDetails ? "" : "wallet_title", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            if viewModel.state.cardModel != nil {
                viewModel.navigation.mainToSettings.toggle()
            }
        }, label: { Image("verticalDots")
            .foregroundColor(Color.tangemTapGrayDark6)
            .frame(width: 44.0, height: 44.0, alignment: .center)
            .offset(x: 10.0, y: 0.0)
        })
        .accessibility(label: Text("voice_over_open_card_details"))
        .padding(0.0)
        )
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.onAppear()
        }
        .navigationBarHidden(isNavBarHidden)
        .ignoresKeyboard()
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .filter {_ in !navigation.mainToSettings
                        && !navigation.mainToSend
                        && !navigation.mainToCreatePayID
                        && !navigation.mainToSendChoise
                        && !navigation.mainToBuyCrypto
                        && !navigation.mainToAddTokens
                        && !navigation.mainToTokenDetails
                        && !navigation.mainToSellCrypto
                        && !navigation.mainToCardOnboarding
                    }
                    .delay(for: 0.5, scheduler: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)) { _ in
            viewModel.state.cardModel?.update()
        }
        .onReceive(navigation
                    .$mainToQR
                    .filter { $0 }
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main),
                   perform: { _ in
                    navigation.mainToQR = false
                    let qrView = QRCodeView(title: String(format: "wallet_qr_title_format".localized, viewModel.wallets!.first!.blockchain.displayName),
                                            shareString: viewModel.cardModel!.walletModels!.first!.shareAddressString(for: viewModel.selectedAddressIndex))
                    
                    viewControllerHolder?.present(style: .overCurrentContext,
                                                  transitionStyle: .crossDissolve) { qrView }
                   })
        .alert(item: $viewModel.error) { $0.alert }
    }
    
    var bottomButtons: some View {
        HStack(alignment: .center) {
            scanButton
                .sheet(isPresented: $navigation.mainToCardOnboarding, content: {
                    OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                        .presentation(modal: viewModel.isOnboardingModal, onDismissalAttempt: {}, onDismissed: viewModel.onboardingDismissed)
                        .environmentObject(navigation)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            viewModel.isOnboardingModal = value
                        })
                })
            
            if viewModel.canCreateWallet {
                createWalletButton
            }
            
            if !viewModel.canCreateWallet && viewModel.canBuyCrypto && !(viewModel.cardModel?.isMultiWallet ?? true)  {
                exchangeCryptoButton
            }
            
            if let cardModel = viewModel.cardModel, !cardModel.isMultiWallet,
               (!viewModel.canCreateWallet || (cardModel.isTwinCard && cardModel.hasBalance)) {
                sendButton
                    .sheet(isPresented: $navigation.mainToSend) {
                        if let sellRequest = viewModel.sellCryptoRequest {
                            let blockchain = viewModel.wallets!.first!.blockchain
                            SendView(viewModel: viewModel.assembly.makeSellCryptoSendViewModel(
                                        with: Amount(with: blockchain, value: sellRequest.amount),
                                        destination: sellRequest.targetAddress,
                                        blockchain: blockchain,
                                        card: viewModel.state.cardModel!), onSuccess: {})
                                .environmentObject(navigation)
                        } else {
                            SendView(viewModel: viewModel.assembly.makeSendViewModel(
                                        with: viewModel.amountToSend!,
                                        blockchain: viewModel.wallets!.first!.blockchain,
                                        card: viewModel.state.cardModel!), onSuccess: {})
                                .environmentObject(navigation) // Fix for crash (Fatal error: No ObservableObject of type NavigationCoordinator found.) which appearse time to time. May be some bug with environment object O_o
                        }
                    }
                    .actionSheet(isPresented: $navigation.mainToSendChoise) {
                        ActionSheet(title: Text("wallet_choice_wallet_option_title"),
                                    message: nil,
                                    buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])
                        
                    }
            }
            
        }
    }
    
}



struct MainView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly(for: .stellar)
    
    static var previews: some View {
        NavigationView {
            MainView(viewModel: assembly.makeMainViewModel())
                .environmentObject(assembly.services.navigationCoordinator)
        }
        .previewGroup(devices: [.iPhone12ProMax])
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.locale, .init(identifier: "en"))
    }
}
