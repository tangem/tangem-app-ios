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
                    Image("card_ff32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: nil, alignment: .center)
                    VStack {
//                        if self.cardViewModel.isWalletLoading {
//                            ActivityIndicatorView(isAnimating: true, style: .large)
//                                .padding(.bottom, 16.0)
//                        } else {
                        if self.viewModel.cardViewModel.wallet != nil {
                                BalanceView(balanceViewModel: self.viewModel.cardViewModel.balanceViewModel)
                            }
                      //  }
                        if self.viewModel.cardViewModel.wallet != nil  {
                            AddressDetailView(
                                address: self.viewModel.cardViewModel.wallet!.address,
                                payId: self.viewModel.cardViewModel.payId,
                                exploreURL: self.viewModel.cardViewModel.wallet!.exploreUrl,
                                showQr: self.$viewModel.showQr,
                                showPayId: self.$viewModel.showCreatePayid)
                        }
                    }
                        Spacer()
                    }
                }
            }
            HStack(alignment: .center, spacing: 8.0) {
                Button(action: {
                    self.viewModel.scan()
                }) {
                    HStack(alignment: .center) {
                        Text("details_button_scan")
                        Spacer()
                        Image("arrow.right")
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .small, colorStyle: .black))
                Button(action: {
                    
                }) { HStack(alignment: .center, spacing: 16.0) {
                    Text("details_button_send")
                    Spacer()
                    Image("shopBag")
                }
                .padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .green))
                .animation(.easeIn)
                .transition(.offset(x: 400.0, y: 0.0))
                
            }
        }
        .padding(.bottom, 16.0)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            
        }, label: { Image("verticalDots")
            .foregroundColor(Color.tangemTapBlack)
            .frame(width: 44.0, height: 44.0, alignment: .center)
            .offset(x: 10.0, y: 0.0)
        }).padding(0.0)
        )
            .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
    }
}


struct DetailsView_Previews: PreviewProvider {
    @State static var sdkService = TangemSdkService()
    
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: DetailsViewModel(cardViewModel: CardViewModel(card: Card.testCard), sdkService: $sdkService))
        }
    }
}
