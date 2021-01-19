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

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var sendChoiceButtons: [ActionSheet.Button] {
        let symbols = viewModel
            .state
            .wallet?
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
        if let walletModel = self.viewModel.state.cardModel?.state.walletModel {
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
        if let walletModel = self.viewModel.state.cardModel?.state.walletModel {
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
        TangemVerticalButton(isLoading: viewModel.isScanning,
                             title: "wallet_button_scan",
                             image: "scan") {
            withAnimation {
                self.viewModel.scan()
            }
        }
        .buttonStyle(TangemButtonStyle(color: .black))
    }
    
    var createWalletButton: some View {
        TangemLongButton(isLoading: viewModel.isCreatingWallet,
                         title: viewModel.isTwinCard ? "wallet_button_create_twin_wallet" : "wallet_button_create_wallet",
                         image: "arrow.right") {
            viewModel.createWallet()
        }
        .buttonStyle(TangemButtonStyle(color: .green, isDisabled: !viewModel.canCreateWallet))
        .disabled(!viewModel.canCreateWallet)
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
                                self.viewModel.warningButtonAction(at: $0, priority: $1)
                            })
                            .padding(.horizontal, 16)
                            
                            ForEach(self.pendingTransactionViews) { $0 }
                            
                            if self.shouldShowEmptyView {
                                ErrorView(
                                    title: viewModel.isTwinCard ? "wallet_error_empty_twin_card".localized : "wallet_error_empty_card".localized,
                                    subtitle: viewModel.isTwinCard ? "wallet_error_empty_twin_card_subtitle".localized : "wallet_error_empty_card_subtitle".localized
                                )
                            } else {
                                if self.shouldShowBalanceView {
                                    BalanceView(balanceViewModel: self.viewModel.state.cardModel!.state.walletModel!.balanceViewModel)
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
                                                  cardViewModel: self.viewModel.state.cardModel!)
                                
                                Color.clear.frame(width: 1, height: 1, alignment: .center)
                                    .sheet(isPresented: self.$navigation.mainToCreatePayID, content: {
                                        CreatePayIdView(cardId: self.viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
                                                        cardViewModel: self.viewModel.state.cardModel!)
                                    })
                                
                                Color.clear.frame(width: 1, height: 1, alignment: .center)
                                    .sheet(isPresented: self.$navigation.mainToQR) {
                                        QRCodeView(title: String(format: "wallet_qr_title_format".localized, self.viewModel.state.wallet!.blockchain.displayName),
                                                   shareString: self.viewModel.state.cardModel!.state.walletModel!.shareAddressString(for: self.viewModel.selectedAddressIndex))
                                            .transition(AnyTransition.move(edge: .bottom))
                                    }
                            }
                        }
                    }
                }
            }
            HStack(alignment: .center, spacing: 8.0) {
                
                scanButton
                
                if self.viewModel.state.cardModel != nil {
                    if viewModel.canCreateWallet {
                        createWalletButton
                    } else {
                        if self.viewModel.state.cardModel!.canTopup {
                            TangemVerticalButton(isLoading: false,
                                                 title: "wallet_button_topup",
                                                 image: "arrow.up") {
                                if self.viewModel.topupURL != nil {
                                    self.navigation.mainToTopup = true
                                }
                            }
                            .buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
                        }
                        TangemVerticalButton(isLoading: false,
                                             title: "wallet_button_send",
                                             image: "arrow.right") {
                            self.viewModel.sendTapped()
                        }
                        .buttonStyle(TangemButtonStyle(color: .green, isDisabled: !self.viewModel.canSend))
                        .disabled(!self.viewModel.canSend)
                        .sheet(isPresented: $navigation.mainToSend) {
                            SendView(viewModel: self.viewModel.assembly.makeSendViewModel(
                                        with: self.viewModel.amountToSend!,
                                        card: self.viewModel.state.cardModel!), onSuccess: {})
                        }
                        .actionSheet(isPresented: self.$navigation.mainToSendChoise) {
                            ActionSheet(title: Text("wallet_choice_wallet_option_title"),
                                        message: nil,
                                        buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])
                            
                        }
                    }
                }
                
            }
            .padding(.top, 8)
            .padding(.bottom, 16.0)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(viewModel.navigation.mainToSettings || viewModel.navigation.mainToTopup ? "" : "wallet_title", displayMode: .inline)
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
                        && navigation.mainToCreatePayID
                    }
                    .delay(for: 0.3, scheduler: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)) { _ in
            viewModel.state.cardModel?.update()
        }
        .alert(item: $viewModel.error) { $0.alert }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(viewModel: Assembly.previewAssembly.makeMainViewModel())
                .environmentObject(Assembly.previewAssembly.navigationCoordinator)
        }
        .deviceForPreview(.iPhone12Pro)
    }
}
