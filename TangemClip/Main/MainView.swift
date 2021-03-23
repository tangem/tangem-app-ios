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
                        
                        Text("URL saved on card " + (viewModel.cardUrl ?? "Unknown"))
                            .foregroundColor(.tangemTapGrayDark6)
                        Text(logger.logs)
                    }
                }
                .frame(width: geometry.size.width)
            }
            
            .onReceive(viewModel.$isWithNdef, perform: { isWithNdef in
                if isWithNdef {
                    viewModel.scanCard()
                }
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
