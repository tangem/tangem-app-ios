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
                        switch viewModel.state {
                        case .notScannedYet:
                            Text("main_hint")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                        case .card(let cardModel):
                            if viewModel.isCardEmpty {
                                ErrorView(title: "main_error_empty_card_title".localized, subtitle: "main_error_empty_card_subtitle".localized)
                            } else {
                                if cardModel.loadingBalancesCounter == 0 && viewModel.tokenItemViewModels.count == 0 {
                                    ErrorView(title: "main_error_empty_wallets_title".localized, subtitle: "main_error_empty_wallets_subtitle".localized)
                                        .animation(.easeInOut)
                                } else {
                                    ForEach(viewModel.tokenItemViewModels) { item in
                                        TokensListItemView(item: item)
                                            .onTapGesture { }
                                    }
                                    .padding(.horizontal, 16)
                                    ActivityIndicatorView(isAnimating: cardModel.loadingBalancesCounter != 0, style: .medium, color: .tangemTapGrayDark6)
                                        .padding(.vertical, 10)
                                        .opacity(cardModel.loadingBalancesCounter > 0 ? 1 : 0)
                                        .animation(.easeInOut)
                                    Color.clear.frame(width: 100, height: viewModel.shouldShowGetFullApp ? 170 : 20, alignment: .center)
                                }
                            }
                        case .unsupported:
                            ErrorView(title: "main_error_unsupported_card_title".localized, subtitle: "main_error_unsupported_card_subtitle".localized)
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
