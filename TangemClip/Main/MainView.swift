//
//  MainView.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import StoreKit

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var shouldShowBalanceView: Bool {
        true
    }
    
    @State var isDisplayingAppStoreOverlay = false
    
    var body: some View {
        VStack {
            Text("main_title")
                .font(.system(size: 17, weight: .medium))
                .frame(height: 44, alignment: .center)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 8) {
                        CardView(image: viewModel.image,
                                 width: geometry.size.width - 32)
                            .fixedSize(horizontal: false, vertical: true)
                        if viewModel.state == .notScannedYet {
                            Text("main_hint")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                        } else {
                            if viewModel.isMultiWallet {
                                ForEach(viewModel.tokenItemViewModels) { item in
                                    TokensListItemView(item: item)
                                        .onTapGesture { }
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
                                } else {
                                    Text("main_unsupported_card")
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    
                }
                .frame(width: geometry.size.width)
            }
            .appStoreOverlay(isPresented: $viewModel.shouldShowGetFullApp) { () -> SKOverlay.Configuration in
                SKOverlay.AppClipConfiguration(position: .bottom)
            }
            
            if viewModel.state == .notScannedYet {
                TangemVerticalButton(isLoading: viewModel.isScanning,
                                     title: "main_button_read_wallets",
                                     image: "scan") {
                    viewModel.scanCard()
                }
                .buttonStyle(TangemButtonStyle(color: .black))
                .padding(.bottom, 48)
            }
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: Assembly.previewAssembly.getMainViewModel())
    }
}
