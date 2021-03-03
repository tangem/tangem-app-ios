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
                self.viewModel.amountToSend = Amount(with: amount, value: 0)
                self.viewModel.showSendScreen()
            }
        }
        return buttons ?? []
    }
    
    var pendingTransactionViews: [PendingTxView] {
        let incTx = self.viewModel.incomingTransactions.map {
            return PendingTxView(txState: .incoming, amount: $0.amount.description, address: $0.sourceAddress)
        }
        
        let outgTx = self.viewModel.outgoingTransactions.map {
            return PendingTxView(txState: .outgoing, amount: $0.amount.description, address: $0.destinationAddress)
        }
        
        return incTx + outgTx
    }
    
    var isUnsupportdState: Bool {
        switch viewModel.state {
        case .unsupported:
            return true
        default:
            return false
        }
    }
    
    var shouldShowEmptyView: Bool {
        if let cardModel = self.viewModel.state.cardModel {
            switch cardModel.state {
            case .empty, .created:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    var shouldShowBalanceView: Bool {
        if let walletModel = self.viewModel.cardModel?.walletModels?.first {
            switch walletModel.state {
            case .idle, .loading, .failed:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    var noAccountView: ErrorView? {
        if let walletModel = self.viewModel.cardModel?.walletModels?.first {
            switch walletModel.state {
            case .noAccount(let message):
                return ErrorView(title: "wallet_error_no_account".localized, subtitle: message)
            default:
                return nil
            }
        }
        
        return nil
    }
    
    var scanButton: some View {
        let scanAction = {
            withAnimation {
                self.viewModel.scan()
            }
        }
        
        let button = viewModel.canTopup && !viewModel.canCreateWallet ?
            (viewModel.cardModel?.cardInfo.isMultiWallet ?? false) ?
            TangemLongButton(isLoading: viewModel.isScanning,
                             title: "wallet_button_scan",
                             image: "scan") {scanAction()}
            .toAnyView()
            :
            TangemVerticalButton(isLoading: viewModel.isScanning,
                                 title: "wallet_button_scan",
                                 image: "scan") { scanAction()}
            .toAnyView() : TangemButton(isLoading: viewModel.isScanning,
                                        title: "wallet_button_scan",
                                        image: "scan") {scanAction()}
            .toAnyView()
        
        return button
            .buttonStyle(TangemButtonStyle(color: .black))
    }
    
    var createWalletButton: some View {
        TangemLongButton(isLoading: viewModel.isCreatingWallet,
                         title: viewModel.isTwinCard ? "wallet_button_create_twin_wallet" : "wallet_button_create_wallet",
                         image: "arrow.right") { viewModel.createWallet()  }
            .buttonStyle(TangemButtonStyle(color: .green, isDisabled: !viewModel.canCreateWallet))
            .disabled(!viewModel.canCreateWallet)
    }
    
    var sendButton: some View {
        let action = { viewModel.sendTapped() }
        
        let button = viewModel.canTopup ?
            TangemVerticalButton(isLoading: false,
                                 title: "wallet_button_send",
                                 image: "arrow.right") { action() }
            .toAnyView() :
            TangemLongButton(isLoading: false,
                             title: "wallet_button_send",
                             image: "arrow.right") { action() }
            .toAnyView()
        
        return button
            .buttonStyle(TangemButtonStyle(color: .green, isDisabled: !self.viewModel.canSend))
            .disabled(!self.viewModel.canSend)
    }
    
    var topupButton: some View {
        TangemVerticalButton(isLoading: false,
                             title: "wallet_button_topup",
                             image: "arrow.up") {
            if self.viewModel.topupURL != nil {
                self.navigation.mainToTopup = true
            }
        }
        .buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
    }
    
    var navigationLinks: AnyView {
        Group {
            NavigationLink(destination: DetailsView(viewModel: viewModel.assembly.makeDetailsViewModel(with: viewModel.state.cardModel!)),
                           isActive: $navigation.mainToSettings)
            
            
            NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardWarningViewModel(isRecreating: false)),
                           isActive: $navigation.mainToTwinsWalletWarning)
            
            NavigationLink(destination: WebViewContainer(url: viewModel.topupURL,
                                                         closeUrl: viewModel.topupCloseUrl,
                                                         title: "wallet_button_topup")
                            .onDisappear { self.viewModel.state.cardModel?.update() },
                           isActive: $navigation.mainToTopup)
            
            NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardOnboardingViewModel(isFromMain: true)),
                           isActive: $navigation.mainToTwinOnboarding)
            
            NavigationLink(destination: TokenDetailsView(viewModel: viewModel.assembly.makeTokenDetailsViewModel(with: viewModel.state.cardModel!,
                                                                                                                 blockchain: viewModel.selectedWallet.blockchain,
                                                                                                                 amountType: viewModel.selectedWallet.amountType)),
                isActive: $navigation.mainToTokenDetails)
        }.toAnyView()
    }
    
    //prevent navbar glitches
    var isNavBarHidden: Bool {
        if navigation.mainToTwinsWalletWarning || navigation.mainToTwinOnboarding {
            return true //hide navbar when navigate to onboarding/warning
        }
        
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationLinks
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 8.0) {
                        CardView(image: self.viewModel.image,
                                 width: geometry.size.width - 32,
                                 currentCardNumber: self.viewModel.cardNumber)
                        
                        if self.isUnsupportdState {
                            ErrorView(title: "wallet_error_unsupported_blockchain".localized, subtitle: "wallet_error_unsupported_blockchain_subtitle".localized)
                        } else {
                            WarningListView(warnings: self.viewModel.warnings, warningButtonAction: {
                                self.viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                            })
                            .padding(.horizontal, 16)
                            
                            if !viewModel.cardModel!.isMultiWallet {
                                ForEach(self.pendingTransactionViews) { $0 }
                            }
                            
                            if self.shouldShowEmptyView {
                                ErrorView(
                                    title: viewModel.isTwinCard ? "wallet_error_empty_twin_card".localized : "wallet_error_empty_card".localized,
                                    subtitle: viewModel.isTwinCard ? "wallet_error_empty_twin_card_subtitle".localized : "wallet_error_empty_card_subtitle".localized
                                )
                            } else {
                                if viewModel.cardModel!.isMultiWallet {
                                    ForEach(viewModel.cardModel!.walletModels!) { walletModel in
                                        ForEach(walletModel.walletItems) { walletItem in
                                            WalletsViewItem(item: walletItem)
                                                .onTapGesture {
                                                    viewModel.onWalletTap(walletItem)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    AddWalletView(action: {
                                                    navigation.mainToAddTokens = true
                                    })
                                        .padding(.horizontal, 16)
                                        .sheet(isPresented: $navigation.mainToAddTokens, content: {
                                            NavigationView {
                                                AddNewTokensView(viewModel: viewModel.assembly.makeAddTokensViewModel(for: viewModel.cardModel!))
                                            }
                                        })
                                    
                                } else {
                                    if self.shouldShowBalanceView {
                                        BalanceView(
                                            balanceViewModel: self.viewModel.cardModel!.walletModels!.first!.balanceViewModel,
                                            tokenViewModels: self.viewModel.cardModel!.walletModels!.first!.tokenViewModels
                                        )
                                        .padding(.horizontal, 16.0)
                                    } else {
                                        if self.noAccountView != nil {
                                            self.noAccountView!
                                        } else {
                                            EmptyView()
                                        }
                                    }
                                    
                                    AddressDetailView(showCreatePayID: self.$navigation.mainToCreatePayID,
                                                      showQr: self.$navigation.mainToQR,
                                                      selectedAddressIndex: self.$viewModel.selectedAddressIndex,
                                                      walletModel: self.viewModel.cardModel!.walletModels!.first!,
                                                      payID: self.viewModel.cardModel!.payId)
                                    
                                    //                                Color.clear.frame(width: 1, height: 1, alignment: .center)
                                    //                                    .sheet(isPresented: self.$navigation.mainToCreatePayID, content: {
                                    //                                        CreatePayIdView(cardId: self.viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
                                    //                                                        cardViewModel: self.viewModel.state.cardModel!)
                                    //                                    })
                                }
                            }
                        }
                    }
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
                    return MailView(dataCollector: dataCollector, emailType: emailCase.emailType)
                }
            ScanTroubleshootingView(isPresented: $navigation.mainToTroubleshootingScan) {
                self.viewModel.scan()
            } requestSupportAction: {
                self.viewModel.failedCardScanTracker.resetCounter()
                self.viewModel.emailFeedbackCase = .scanTroubleshooting
            }

            bottomButtons
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16.0)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(navigation.mainToSettings || navigation.mainToTopup || navigation.mainToTokenDetails ? "" : "wallet_title", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            if self.viewModel.state.cardModel != nil {
                self.viewModel.navigation.mainToSettings.toggle()
            }
        }, label: { Image("verticalDots")
            .foregroundColor(Color.tangemTapGrayDark6)
            .frame(width: 44.0, height: 44.0, alignment: .center)
            .offset(x: 10.0, y: 0.0)
        })
        .padding(0.0)
        )
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .onAppear {
            self.viewModel.onAppear()
        }
        .navigationBarHidden(isNavBarHidden)
        .ignoresKeyboard()
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .filter {_ in !navigation.mainToSettings
                        && !navigation.mainToSend
                        && !navigation.mainToCreatePayID
                        && !navigation.mainToSendChoise
                        && !navigation.mainToTopup
                        && !navigation.mainToTwinOnboarding
                        && !navigation.mainToTwinsWalletWarning
                        && !navigation.mainToAddTokens
                    }
                    .delay(for: 0.3, scheduler: DispatchQueue.global())
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
            
            if viewModel.canCreateWallet {
                createWalletButton
            } else {
                if !viewModel.cardModel!.isMultiWallet {
                    if viewModel.canTopup  {
                        topupButton
                    }
                    
                    sendButton
                        .sheet(isPresented: $navigation.mainToSend) {
                            SendView(viewModel: self.viewModel.assembly.makeSendViewModel(
                                        with: self.viewModel.amountToSend!,
                                        walletIndex: 0,
                                        card: self.viewModel.state.cardModel!), onSuccess: {})
                                                                    .environmentObject(navigation) // Fix for crash (Fatal error: No ObservableObject of type NavigationCoordinator found.) which appearse time to time. May be some bug with environment object O_o
                                        
                        }
                        .actionSheet(isPresented: self.$navigation.mainToSendChoise) {
                            ActionSheet(title: Text("wallet_choice_wallet_option_title"),
                                        message: nil,
                                        buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])
                            
                        }
                } else {
                    Spacer()
                }

            }
        }
    }
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(viewModel: Assembly.previewAssembly.makeMainViewModel())
                .environmentObject(Assembly.previewAssembly.navigationCoordinator)
        }
        .previewGroup(devices: [.iPhone8Plus])
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.locale, .init(identifier: "en"))
    }
}
