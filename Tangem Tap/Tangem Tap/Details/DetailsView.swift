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
import Combine

struct DetailsView: View {
    @ObservedObject var viewModel: DetailsViewModel
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
                    VStack(spacing: 48.0) {
                        if self.viewModel.cardViewModel.image != nil {
                            Image(uiImage: self.viewModel.cardViewModel.image!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: nil, alignment: .center)
                        }
                        VStack {
                            if self.viewModel.cardViewModel.isWalletLoading {
                                ActivityIndicatorView(isAnimating: true, style: .medium)
                                    .padding(.bottom, 16.0)
                            } else {
                                if self.viewModel.cardViewModel.noAccountMessage != nil {
                                    ErrorView(title: "error_title_no_account".localized, subtitle: self.viewModel.cardViewModel.noAccountMessage!)
                                } else {
                                    if self.viewModel.cardViewModel.wallet != nil {
                                        BalanceView(balanceViewModel: self.viewModel.cardViewModel.balanceViewModel)
                                        AddressDetailView().environmentObject(self.viewModel.cardViewModel)
                                    } else {
                                        if self.viewModel.cardViewModel.walletManager == nil  {
                                             ErrorView(title: "error_title_unsupported_blockchain".localized, subtitle: "error_subtitle_unsupported_blockchain".localized)
                                        } else {
                                            ErrorView(title: "error_title_empty_card".localized, subtitle: "error_subtitle_empty_card".localized)
                                        }
                                    }
                                }
                                
                            }
                        }
                        Spacer()
                    }
                }
            }
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
                Button(action: {
                    if self.viewModel.cardViewModel.wallet == nil && self.viewModel.cardViewModel.walletManager != nil  {
                        self.viewModel.createWallet()
                    } else {
                        self.viewModel.showSend = true
                    }
                }) { HStack(alignment: .center, spacing: 16.0) {
                    Text(self.viewModel.cardViewModel.wallet == nil && self.viewModel.cardViewModel.walletManager != nil  ? "details_button_create_wallet" : "details_button_send")
                    Spacer()
                    Image("arrow.right")
                }
                .padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green, isDisabled: self.viewModel.cardViewModel.wallet == nil && self.viewModel.cardViewModel.walletManager != nil  ? false : !self.viewModel.cardViewModel.canExtract))
                .animation(.easeIn)
                .disabled(self.viewModel.cardViewModel.wallet == nil && self.viewModel.cardViewModel.walletManager != nil  ? false : !self.viewModel.cardViewModel.canExtract)
                .transition(.offset(x: 400.0, y: 0.0))
                .sheet(isPresented: $viewModel.showSend) {
                    ExtractView(model: ExtractViewModel(cardViewModel: self.$viewModel.cardViewModel,
                                                        sdkSerice: self.$viewModel.sdkService))
                }
                
            }
        }
            .padding(.bottom, 16.0)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle("details_title", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.viewModel.showSettings = true
                
            }, label: { Image("verticalDots")
                .foregroundColor(Color.tangemTapGrayDark6)
                .frame(width: 44.0, height: 44.0, alignment: .center)
                .offset(x: 10.0, y: 0.0)
            })
                .padding(0.0)
                .sheet(isPresented: $viewModel.showSettings) {
                    SettingsView(viewModel: SettingsViewModel(cardViewModel: self.$viewModel.cardViewModel, sdkSerice: self.$viewModel.sdkService))
                }
        )
            .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
    }
}


struct DetailsView_Previews: PreviewProvider {
    @State static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        service.cards[Card.testCardNoWallet.cardId!] = CardViewModel(card: Card.testCardNoWallet)
        return service
    }()
    
    static var previews: some View {
        Group {
            NavigationView {
                DetailsView(viewModel: DetailsViewModel(cid: Card.testCard.cardId!, sdkService: $sdkService))
            }
            
            NavigationView {
                DetailsView(viewModel: DetailsViewModel(cid: Card.testCardNoWallet.cardId!, sdkService: $sdkService))
            }
        }
    }
}
