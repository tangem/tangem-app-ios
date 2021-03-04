//
//  TokenDetailsView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var pendingTransactionViews: [PendingTxView] {
        let incTx = viewModel.incomingTransactions.map {
            return PendingTxView(txState: .incoming, amount: $0.amount.description, address: $0.sourceAddress)
        }
        
        let outgTx = viewModel.outgoingTransactions.map {
            return PendingTxView(txState: .outgoing, amount: $0.amount.description, address: $0.destinationAddress)
        }
        
        return incTx + outgTx
    }
    
    var navigationLinks: AnyView {
        Group {
            NavigationLink(destination: WebViewContainer(url: viewModel.topupURL,
                                                         closeUrl: viewModel.topupCloseUrl,
                                                         title: "wallet_button_topup")
                            .onDisappear { self.viewModel.card.update() },
                           isActive: $navigation.detailsToTopup)
        }.toAnyView()
    }
    
    var bottomButtons: some View {
        HStack(alignment: .center) {
            if viewModel.canTopup  {
                TwinButton(leftImage: "arrow.up",
                           leftTitle: "wallet_button_topup",
                           leftAction: { navigation.detailsToTopup = true },
                           leftIsDisabled: false,
                           
                           rightImage: "arrow.right",
                           rightTitle: "wallet_button_send",
                           rightAction: { navigation.detailsToSend = true },
                           rightIsDisabled: !viewModel.canSend)
            } else {
                TangemLongButton(isLoading: false,
                                 title: "wallet_button_send",
                                 image: "arrow.right") {
                    viewModel.assembly.reset()
                    navigation.detailsToSend = true
                }
                .buttonStyle(TangemButtonStyle(color: .green, isDisabled: !self.viewModel.canSend))
                .disabled(!self.viewModel.canSend)
            }
        }
        .sheet(isPresented: $navigation.detailsToSend) {
            if let amountToSend = viewModel.amountToSend {
                SendView(viewModel: viewModel.assembly.makeSendViewModel(
                            with: amountToSend,
                            walletIndex: 0,
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
            
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 8.0) {
                        ForEach(self.pendingTransactionViews) { $0 }
                        
                        if let walletModel = viewModel.walletModel {
                            BalanceAddressView(walletModel: walletModel)
                        }
                        bottomButtons
                            .padding(.top, 16)
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
            .foregroundColor(viewModel.canDelete ? Color.tangemTapGrayDark6 : Color.tangemTapGrayDark4)
        })
        .disabled(!viewModel.canDelete)
        .padding(0.0)
        )
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .ignoresKeyboard()
    }
}

struct TokenDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TokenDetailsView(viewModel: Assembly.previewAssembly.makeTokenDetailsViewModel(with: CardViewModel.previewCardViewModel, blockchain: .bitcoin(testnet: false)))
                .environmentObject(Assembly.previewAssembly.navigationCoordinator)
        }
        .previewGroup(devices: [.iPhone8Plus])
    }
}
