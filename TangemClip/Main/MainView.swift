//
//  MainView.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var shouldShowBalanceView: Bool {
        true
    }
    
    var body: some View {
        VStack {
            Text("Tangem Clip")
                .font(.system(size: 17, weight: .medium))
                .frame(height: 44, alignment: .center)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 8.0) {
                        CardView(image: viewModel.image,
                                 width: geometry.size.width - 32)
//                        Text("URL saved on card " + (viewModel.cardUrl ?? "Unknown"))
//                            .foregroundColor(.tangemTapGrayDark6)
                        if viewModel.state == .unsupported {
                            Text("Tap \"Scan card\" button to load wallet information from card")
                                .padding()
                        } else {
                            if viewModel.isMultiWallet {
                                ForEach(viewModel.tokenItemViewModels) { item in
                                    TokensListItemView(item: item)
                                        .onTapGesture {
                                            //                                        viewModel.onWalletTap(item)
                                        }
                                }
                                .padding(.horizontal, 16)
                                
                            } else {
                                if let cardModel = viewModel.cardModel, cardModel.walletModels.count > 0 {
                                    if shouldShowBalanceView {
                                        BalanceView(
                                            balanceViewModel: cardModel.walletModels.first!.balanceViewModel,
                                            tokenViewModels: cardModel.walletModels.first!.tokenViewModels
                                        )
                                        .padding(.horizontal, 16.0)
                                    } else {
                                        EmptyView()
                                    }
                                    
                                    AddressDetailView(selectedAddressIndex: $viewModel.selectedAddressIndex,
                                                      walletModel: cardModel.walletModels.first!)
                                    
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
                .frame(width: geometry.size.width)
            }
            
            .onReceive(viewModel.$isWithNdef, perform: { isWithNdef in
                //                if isWithNdef {
                //                    viewModel.scanCard()
                //                }
            })
            .ignoresKeyboard()
            TangemLongButton(isLoading: viewModel.isScanning,
                             title: "Scan card",
                             image: "scan") {
                viewModel.scanCard()
            }
            .buttonStyle(TangemButtonStyle(color: .black))
            .padding(.bottom, 18)
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: Assembly.previewAssembly.getMainViewModel())
    }
}
