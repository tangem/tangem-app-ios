//
//  ContentView.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                        VStack(spacing: 8.0) {
                            CardView(image: UIImage(),
                                     width: geometry.size.width - 32,
                                     currentCardNumber: Int(viewModel.cardNumber),
                                     cid: viewModel.cardNumber)
                                .background(Color.tangemTapGrayDark4)
                            Button("Scan card", action: {
                                viewModel.scanCard()
                            })
                            Text("URL saved on card " + (viewModel.cardUrl ?? "Unknown"))
                                .foregroundColor(.tangemTapGrayDark6)
                            
//                            if !viewModel.cardModel!.isMultiWallet {
//                                ForEach(self.pendingTransactionViews) { $0 }
//                            }
                            
//                            if self.shouldShowEmptyView {
//                                ErrorView(
//                                    title: "wallet_error_empty_card".localized,
//                                    subtitle: "wallet_error_empty_card_subtitle".localized
//                                )
//                            } else {
//                                if viewModel.isMultiWallet {
////                                    ForEach(viewModel.cardModel!.walletItemViewModels!) { item in
////                                        WalletsViewItem(item: item)
////                                            .onTapGesture {
////                                                viewModel.onWalletTap(item)
////                                            }
////                                    }
////                                    .padding(.horizontal, 16)
//
////                                    AddWalletView(action: {
////                                        navigation.mainToAddTokens = true
////                                    })
////                                    .padding(.horizontal, 16)
////                                    .sheet(isPresented: $navigation.mainToAddTokens, content: {
////                                        NavigationView {
////                                            AddNewTokensView(viewModel: viewModel.assembly.makeAddTokensViewModel(for: viewModel.cardModel!))
////                                                .environmentObject(navigation)
////                                        }
////                                    })
//                                    Color.red
//
//                                } else {
//                                    if self.shouldShowBalanceView {
//                                        BalanceView(
//                                            balanceViewModel: ,
//                                            tokenViewModels: self.viewModel.cardModel!.walletModels!.first!.tokenViewModels
//                                        )
//                                        .padding(.horizontal, 16.0)
//                                    }
                                    
//                                    AddressDetailView(showCreatePayID: self.$navigation.mainToCreatePayID,
//                                                      showQr: self.$navigation.mainToQR,
//                                                      selectedAddressIndex: self.$viewModel.selectedAddressIndex,
//                                                      walletModel: self.viewModel.cardModel!.walletModels!.first!,
//                                                      payID: self.viewModel.cardModel!.payId)
                                    
                                    //                                Color.clear.frame(width: 1, height: 1, alignment: .center)
                                    //                                    .sheet(isPresented: self.$navigation.mainToCreatePayID, content: {
                                    //                                        CreatePayIdView(cardId: self.viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
                                    //                                                        cardViewModel: self.viewModel.state.cardModel!)
                                    //                                    })
//                                }
//                            }
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(trailing: Button(action: {
                
            }, label: { Image("verticalDots")
                .foregroundColor(Color.tangemTapGrayDark6)
                .frame(width: 44.0, height: 44.0, alignment: .center)
                .offset(x: 10.0, y: 0.0)
            })
            .padding(0.0)
            )
            .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
            .onAppear {
            }
            .ignoresKeyboard()
        }
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: MainViewModel(cid: "CB47000000000435", cardsRepository: Assembly.previewAssembly.cardsRepository))
    }
}

struct BalanceViewModel {
    let isToken: Bool
    let hasTransactionInProgress: Bool
    let name: String
    let fiatBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryFiatBalance: String
    let secondaryName: String
}
