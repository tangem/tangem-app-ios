//
//  DetailsView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIPullToRefresh
import TangemSdk

struct DetailsView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    @State var model = DetailsViewModel()
    
    var body: some View {
        ZStack {
            Color.tangemBg
                .edgesIgnoringSafeArea(.all)
            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        Image("card_ff32")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: nil, alignment: .center)
                            .padding(.bottom, 48.0)
                        if self.tangemSdkModel.wallet != nil {
                            VStack {
                            BalanceView(walletModel: self.tangemSdkModel.wallet!)
                                AddressDetailView(
                                    address: self.tangemSdkModel.wallet!.address,
                                    payId: self.tangemSdkModel.wallet!.payId,
                                    detailsViewModel: self.$model)
                            }
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
        }
        .onAppear {
            
        }
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var model: TangemSdkModel = {
        var model = TangemSdkModel()
        model.wallet = WalletModel(card: Card.testCard)
        return model
    }()
    
    static var previews: some View {
        DetailsView()
        .environmentObject(model)
    }
}
