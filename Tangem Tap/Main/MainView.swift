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
    
    var shouldShowAlertView: Bool {
        if let cardModel = self.viewModel.state.cardModel, !cardModel.canSign {
            return true
        }
        return false
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
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 8.0) {
                        if self.viewModel.image != nil {
                            Image(uiImage: self.viewModel.image!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width - 32.0, height: nil, alignment: .center)
                                .padding(.vertical, 16.0)
                        } else {
                            Color.tangemTapGrayLight4
                                .opacity(0.5)
                                .frame(width: geometry.size.width - 32.0, height: 180, alignment: .center)
                                .cornerRadius(6)
                                .padding(.vertical, 16.0)
                        }

                        if self.shouldShowAlertView {
                            AlertCardView(title: "common_warning".localized,
                                          message: "alert_old_card".localized)
                                .padding(.horizontal, 16.0)
                        }
                        
                        if self.isUnsupportdState {
                             ErrorView(title: "wallet_error_unsupported_blockchain".localized, subtitle: "wallet_error_unsupported_blockchain_subtitle".localized)
                        } else {
                            ForEach(self.pendingTransactionViews) { $0 }
                            
                            if self.shouldShowEmptyView {
                                 ErrorView(title: "wallet_error_empty_card".localized, subtitle: "wallet_error_empty_card_subtitle".localized)
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
                                AddressDetailView(showCreatePayID: self.$viewModel.navigation.showCreatePayID,
                                                  showQr: self.$viewModel.navigation.showQRAddress,
                                                  selectedAddressIndex: self.$viewModel.selectedAddressIndex,
                                                  cardViewModel: self.viewModel.state.cardModel!)
                                
                                EmptyView()
                                    .sheet(isPresented: self.$viewModel.navigation.showCreatePayID, content: {
                                        CreatePayIdView(cardId: self.viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
                                                        cardViewModel: self.viewModel.state.cardModel!)
                                    })
                                
                                EmptyView()
                                    .sheet(isPresented: self.$viewModel.navigation.showQRAddress) {
                                        // VStack {
                                        //    Spacer()
                                        QRCodeView(title: String(format: "wallet_qr_title_format".localized, self.viewModel.state.wallet!.blockchain.displayName),
                                                   shareString: self.viewModel.state.cardModel!.state.walletModel!.shareAddressString(for: self.viewModel.selectedAddressIndex))
                                            .transition(AnyTransition.move(edge: .bottom))
                                        //   Spacer()
                                        // }
                                        // .background(Color(red: 0, green: 0, blue: 0, opacity: 0.74))
                                    }
                            }
                        }
                    }
                }

            }
            HStack(alignment: .center, spacing: 8.0) {
                TangemVerticalButton(isLoading: self.viewModel.isScanning,
                                     title: "wallet_button_scan",
                                     image: "scan") {
                    withAnimation {
                        self.viewModel.scan()
                    }
                }.buttonStyle(TangemButtonStyle(color: .black))
                
                if self.viewModel.state.cardModel != nil {
                    if viewModel.canCreateWallet {
                        TangemLongButton(isLoading: self.viewModel.isCreatingWallet,
                                         title: "wallet_button_create_wallet",
                                         image: "arrow.right") {
                            self.viewModel.createWallet()
                        }.buttonStyle(TangemButtonStyle(color: .green, isDisabled: !self.viewModel.canCreateWallet))
                        .disabled(!self.viewModel.canCreateWallet)
                    } else {
                        if self.viewModel.state.cardModel!.canTopup {
                            TangemVerticalButton(isLoading: false,
                                                 title: "wallet_button_topup",
                                                 image: "arrow.up") {
                                self.viewModel.navigation.showTopup = true
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
                        .sheet(isPresented: $viewModel.navigation.showSend) {
                            SendView(viewModel: self.viewModel.assembly.makeSendViewModel(
                                        with: self.viewModel.amountToSend!,
                                        card: self.viewModel.state.cardModel!), onSuccess: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    let alert = Alert(title: Text("common_success"),
                                                      message: Text("send_transaction_success"),
                                                      dismissButton: Alert.Button.default(Text("common_ok"),
                                                                                          action: {}))
                                    
                                    self.viewModel.error = AlertBinder(alert: alert)
                                }
                            })
                        }
                        .actionSheet(isPresented: self.$viewModel.navigation.showSendChoise) {
                            ActionSheet(title: Text("wallet_choice_wallet_option_title"),
                                        message: nil,
                                        buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])
                            
                        }
                    }
                }
                if viewModel.navigation.showSettings {
                    NavigationLink(
                        destination: DetailsView(viewModel: viewModel.assembly.makeDetailsViewModel(with: viewModel.state.cardModel!)),
                        isActive: $viewModel.navigation.showSettings,
                        label: { EmptyView() })
                }
                
                NavigationLink(destination: WebViewContainer(url: viewModel.topupURL,
                                                             closeUrl: viewModel.topupCloseUrl,
                                                             title: "wallet_button_topup")
                                .onDisappear {
                                    self.viewModel.state.cardModel?.update()
                                },
                               isActive: $viewModel.navigation.showTopup) {
                    EmptyView()
                }
            }
        }
        .padding(.bottom, 16.0)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(viewModel.navigation.showSettings || viewModel.navigation.showTopup ? "" : "wallet_title", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            if self.viewModel.state.cardModel != nil {
                self.viewModel.navigation.showSettings = true
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
        .ignoresKeyboard()
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .filter {_ in !self.viewModel.navigation.showSettings
                        && !self.viewModel.navigation.showSend
                        && !self.viewModel.navigation.showCreatePayID
                    }
                    .delay(for: 0.3, scheduler: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)) { _ in
            self.viewModel.state.cardModel?.update()
        }
        .alert(item: $viewModel.error) { $0.alert }
        
    }
}


struct DetailsView_Previews: PreviewProvider {
    static var testVM: MainViewModel {
        let assembly = Assembly.previewAssembly
        let vm = assembly.makeMainViewModel()
        vm.state = .card(model: CardViewModel.previewCardViewModel)
        return vm
    }
    
    static var testNoWalletVM: MainViewModel {
        let assembly = Assembly.previewAssembly
        let vm = assembly.makeMainViewModel()
        vm.state = .card(model: CardViewModel.previewCardViewModelNoWallet)
        return vm
    }
    
    static var previews: some View {
        Group {
            NavigationView {
                MainView(viewModel: testVM)
            }
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            .previewDisplayName("iPhone 8")
            
            NavigationView {
                MainView(viewModel: testNoWalletVM)
            }
        }
    }
}
