//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct TotalSumBalanceView: View {
    
    @ObservedObject var viewModel: TotalSumBalanceViewModel
    
    var tapOnCurrencySymbol: () -> ()
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("main_page_balance".localized.uppercased())
                        .font(Font.system(size: 14, weight: .medium))
                        .foregroundColor(Color.tangemTextGray)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    Button {
                        tapOnCurrencySymbol()
                    } label: {
                        HStack(spacing: 0) {
                            Text(viewModel.currencyType)
                                .font(Font.system(size: 16, weight: .medium))
                                .foregroundColor(Color.tangemGrayDark)
                                .padding(.trailing, 6)
                            Image("tangemArrowDown")
                                .foregroundColor(Color.tangemTextGray)
                                .padding(.trailing, 20)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 22)
                }
                .padding(.bottom, 4)
                
                HStack(spacing: 0) {
                    Text(viewModel.isLoading ? "wallet_balance_loading".localized : viewModel.totalFiatValueString)
                        .redactedIfPossible(viewModel.isLoading)
                        .if(viewModel.isLoading, transform: { view in
                            view.shimmering()
                        })
                        .font(Font.system(size: 34, weight: .bold))
                        .foregroundColor(Color.tangemGrayDark6)
                        .padding(.leading, 20)
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding([.leading, .trailing], 16)
        }
        .background(Color.clear)
        .onDisappear {
            viewModel.disableLoading()
        }
    }
}
