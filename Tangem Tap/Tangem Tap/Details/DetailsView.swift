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

struct DetailsView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    @State var model = DetailsViewModel()
    
    var isLoading: Bool {
        if case .loading = tangemSdkModel.walletViewModel.state  {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    Image("card_ff32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: nil, alignment: .center)
                        .padding(.bottom, 48.0)
                    VStack {
                        if self.isLoading {
                            ActivityIndicatorView(isAnimating: self.isLoading, style: .large)
                                .padding(.bottom, 16.0)
                        } else {
                            BalanceView(balanceViewModel: self.tangemSdkModel.walletViewModel.balanceViewModel)
                        }
                        AddressDetailView(
                            address: self.tangemSdkModel.walletViewModel.address,
                            payId: self.tangemSdkModel.walletViewModel.payId,
                            exploreURL: self.tangemSdkModel.walletViewModel.wallet.exploreUrl,
                            detailsViewModel: self.$model)
                    }
                }
            }
            HStack(alignment: .center, spacing: 8.0) {
                Button(action: {
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
    static var model: TangemSdkModel = {
        var model = TangemSdkModel()
        model.setupCard(Card.testCard)
        return model
    }()
    
    static var previews: some View {
        NavigationView {
            DetailsView()
                .environmentObject(model)
        }
    }
}
