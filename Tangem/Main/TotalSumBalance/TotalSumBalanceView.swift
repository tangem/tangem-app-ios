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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("main_page_balance".localized.uppercased())
                    .lineLimit(1)
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                    .padding(.leading, 16)
                    .padding(.top, 20)
                
                Spacer()
                
                Button {
                    tapOnCurrencySymbol()
                } label: {
                    HStack(spacing: 0) {
                        Text(viewModel.currencyType)
                            .lineLimit(1)
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
            
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoading {
                    ActivityIndicatorView(isAnimating: true, style: .medium, color: .gray)
                        .frame(height: 33)
                } else {
                    Text(viewModel.totalFiatValueString)
                        .lineLimit(1)
                        .font(Font.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.tangemGrayDark6)
                        .frame(height: 33)
                }
                
                if viewModel.isFailed {
                    Text("main_processing_full_amount".localized)
                        .foregroundColor(Color.tangemWarning)
                        .font(.system(size: 13, weight: .regular))
                        .padding(.top, 2)
                }
            }
            .padding([.bottom, .leading], 16)
        }
        .background(Color.white)
        .onDisappear {
            viewModel.disableLoading()
        }
    }
}
