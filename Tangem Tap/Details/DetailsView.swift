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
    
    var pendingTransactionViews: [PendingTxView] {
        let incTx = self.viewModel.incomingTransactions.map {
            return PendingTxView(txState: .incoming, amount: $0.amount.description, address: $0.sourceAddress)
        }
        
        let outgTx = self.viewModel.outgoingTransactions.map {
            return PendingTxView(txState: .outgoing, amount: $0.amount.description, address: $0.destinationAddress)
        }
        
        return incTx + outgTx
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 8.0) {
                        if self.viewModel.cardViewModel.image != nil {
                            Image(uiImage: self.viewModel.cardViewModel.image!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width - 32.0, height: nil, alignment: .center)
                                .padding(.bottom, 16.0)
                        }

                            if !self.viewModel.cardCanSign {
                                AlertCardView(title: "common_warning".localized,
                                              message: "alert_old_card".localized)
                                    .padding(.horizontal, 16.0)
                            }
                            
                            if self.viewModel.cardViewModel.wallet != nil {
                                
                                ForEach(self.pendingTransactionViews) { $0 }
                                
                                if self.viewModel.cardViewModel.noAccountMessage != nil {
                                    ErrorView(title: "error_title_no_account".localized, subtitle: self.viewModel.cardViewModel.noAccountMessage!)
                                } else {
                                    if self.viewModel.cardViewModel.balanceViewModel != nil {
                                        BalanceView(balanceViewModel: self.viewModel.cardViewModel.balanceViewModel)
                                            .layoutPriority(2)
                                    }
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
                
            }
            .sheet(isPresented: self.$viewModel.showCreatePayID, content: {
                CreatePayIdView(cardId: self.viewModel.cardViewModel.card.cardId ?? "")
                    .environmentObject(self.viewModel.cardViewModel)
            })
            HStack(alignment: .center, spacing: 8.0) {
                TangemButton(isLoading: self.viewModel.isScanning,
                             title: "details_button_scan",
                             image: "scan") {
                                withAnimation {
                                    self.viewModel.scan()
                                }
                }.buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
                
                if self.viewModel.cardViewModel.isCardSupported {
                    if self.viewModel.cardViewModel.wallet == nil {
                        TangemButton(isLoading: self.viewModel.isCreatingWallet,
                                     title: "details_button_create_wallet",
                                     image: "arrow.right") {
                                         self.viewModel.createWallet()
                        }.buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green, isDisabled: !self.viewModel.canCreateWallet))
                        .disabled(!self.viewModel.canCreateWallet)
                    } else {
                        Button(action: {
                            self.viewModel.sendTapped()
                        }) { HStack(alignment: .center, spacing: 16.0) {
                            Text("details_button_send" )
                            Spacer()
                            Image("arrow.right")
                        }
                        .padding(.horizontal)
                        }
                        .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green, isDisabled: !self.viewModel.canSend))
                        .disabled(!self.viewModel.canSend)
                        .sheet(isPresented: $viewModel.showSend) {
                            SendView(viewModel: SendViewModel(amountToSend: self.viewModel.amountToSend!,
                                                              cardViewModel: self.$viewModel.cardViewModel,
                                                              sdkSerice: self.$viewModel.sdkService), onSuccess: {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                                    let alert = Alert(title: Text("common_success"),
                                                                                      message: Text("send_transaction_success"),
                                                                                      dismissButton: Alert.Button.default(Text("common_ok"),
                                                                                                                          action: {}))
                                                                    
                                                                    self.viewModel.error = AlertBinder(alert: alert)
                                                                }
                            })
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
            .onAppear {
                self.viewModel.onAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        .delay(for: 0.3, scheduler: DispatchQueue.global())
        .receive(on: DispatchQueue.main)) { _ in
            self.viewModel.cardViewModel.update(silent: true)
        }
        .alert(item: $viewModel.error) { $0.alert }
        
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
