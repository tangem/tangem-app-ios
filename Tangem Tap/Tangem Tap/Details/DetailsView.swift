//
//  DetailsView.swift
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


struct DetailsView: View {
    @ObservedObject var viewModel: DetailsViewModel
    
    var sendChoiceButtons: [ActionSheet.Button] {
        let symbols = viewModel
            .cardViewModel
            .wallet!
            .amounts
            .filter { $0.key != .reserve && $0.value.value > 0 }
            .values
            .map { $0.self }
        
        let buttons = symbols.map { amount in
            return ActionSheet.Button.default(Text(amount.currencySymbol)) {
                self.viewModel.amountToSend = Amount(with: amount, value: 0)
                self.viewModel.showSend = true
            }
        }
        return buttons
    }
    
    var pendingTransactionView: PendingTxView? {
        if let incTx = self.viewModel.incomingTransactions.first {
            return PendingTxView(txState: .incoming, amount: incTx.amount.description, address: incTx.sourceAddress)
        }
        
        if let outgTx = self.viewModel.outgoingTransactions.first {
            return PendingTxView(txState: .outgoing, amount: outgTx.amount.description, address: outgTx.destinationAddress)
        }
        return nil
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 24.0) {
                        if self.viewModel.cardViewModel.image != nil {
                            Image(uiImage: self.viewModel.cardViewModel.image!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width - 32.0, height: nil, alignment: .center)
                        }
                        VStack {
                            if self.viewModel.cardViewModel.isWalletLoading {
                                ActivityIndicatorView(isAnimating: true, style: .medium)
                                    .padding(.bottom, 16.0)
                            } else {
                                if self.viewModel.cardViewModel.wallet != nil {
                                    self.pendingTransactionView
                                        .padding(.bottom, 8.0)
                                    
                                    if self.viewModel.cardViewModel.noAccountMessage != nil {
                                        ErrorView(title: "error_title_no_account".localized, subtitle: self.viewModel.cardViewModel.noAccountMessage!)
                                    } else {
                                        BalanceView(balanceViewModel: self.viewModel.cardViewModel.balanceViewModel)
                                    }
                                    AddressDetailView(showCreatePayID: self.$viewModel.showCreatePayID)
                                        .environmentObject(self.viewModel.cardViewModel)
                                } else {
                                    if !self.viewModel.cardViewModel.isCardSupported  {
                                        ErrorView(title: "error_title_unsupported_blockchain".localized, subtitle: "error_subtitle_unsupported_blockchain".localized)
                                    } else {
                                        ErrorView(title: "error_title_empty_card".localized, subtitle: "error_subtitle_empty_card".localized)
                                    }
                                }
                                
                                
                            }
                        }
                        Spacer()
                    }
                }
                
            }
            .sheet(isPresented: self.$viewModel.showCreatePayID, content: {
                          CreatePayIdView(cardId: self.viewModel.cardViewModel.card.cardId ?? "")
                              .environmentObject(self.viewModel.cardViewModel)
                  })
            HStack(alignment: .center, spacing: 8.0) {
                Button(action: {
                    withAnimation {
                        self.viewModel.scan()
                    }
                }) {
                    HStack(alignment: .center) {
                        Text("details_button_scan")
                        Spacer()
                        Image("scan")
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
                
                if self.viewModel.cardViewModel.isCardSupported {
                    Button(action: {
                        self.viewModel.actionButtonTapped()
                    }) { HStack(alignment: .center, spacing: 16.0) {
                        Text(self.viewModel.canCreateWallet ? "details_button_create_wallet" :  "details_button_send" )
                        Spacer()
                        Image("arrow.right")
                    }
                    .padding(.horizontal)
                    }
                    .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green, isDisabled: self.viewModel.isActionButtonDisabled))
                    .disabled(self.viewModel.isActionButtonDisabled)
                    .transition(.offset(x: 400.0, y: 0.0))
                    .sheet(isPresented: $viewModel.showSend) {
                        ExtractView(viewModel: ExtractViewModel(amountToSend: self.viewModel.amountToSend!,
                                                                cardViewModel: self.$viewModel.cardViewModel,
                                                                sdkSerice: self.$viewModel.sdkService))
                    }
                    .actionSheet(isPresented: self.$viewModel.showSendChoise) {
                        ActionSheet(title: Text("details_choice_wallet_option_title"),
                                    message: nil,
                                    buttons: sendChoiceButtons + [ActionSheet.Button.cancel()])
                        
                    }
                }
            }
            if viewModel.showSettings {
                NavigationLink(
                    destination: SettingsView(viewModel: SettingsViewModel(cardViewModel: self.$viewModel.cardViewModel, sdkSerice: self.$viewModel.sdkService)),
                    isActive: $viewModel.showSettings,
                    label: {
                        EmptyView()
                    })
            }
        }
        .padding(.bottom, 16.0)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(viewModel.showSettings ? "" : "details_title", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            self.viewModel.showSettings = true
            
        }, label: { Image("verticalDots")
            .foregroundColor(Color.tangemTapGrayDark6)
            .frame(width: 44.0, height: 44.0, alignment: .center)
            .offset(x: 10.0, y: 0.0)
        })
        .padding(0.0)
        )
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .alert(isPresented: self.$viewModel.cardViewModel.showSendAlert) { () -> Alert in
            return Alert(title: Text("common_success"),
                         message: Text("send_transaction_success"),
                         dismissButton: Alert.Button.default(Text("common_ok"),
                                                             action: {}))
            
        }
      
    }
}


struct DetailsView_Previews: PreviewProvider {
    static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        service.cards[Card.testCardNoWallet.cardId!] = CardViewModel(card: Card.testCardNoWallet)
        return service
    }()
    
    static var previews: some View {
        Group {
            NavigationView {
                DetailsView(viewModel: DetailsViewModel(cid: Card.testCard.cardId!, sdkService: sdkService))
            }
            
            NavigationView {
                DetailsView(viewModel: DetailsViewModel(cid: Card.testCardNoWallet.cardId!, sdkService: sdkService))
            }
        }
    }
}
