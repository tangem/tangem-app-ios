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

struct DetailsView: View {
    @EnvironmentObject var tangemSdkModel: TangemSdkModel
    @ObservedObject var model = DetailsViewModel()
    
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
                            BalanceView(walletModel: self.tangemSdkModel.wallet!)
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
    static var previews: some View {
        DetailsView()
    }
}
