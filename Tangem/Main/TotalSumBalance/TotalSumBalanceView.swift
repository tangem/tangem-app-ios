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
                
                HStack(spacing: 0) {
                    if viewModel.isLoading {
                        ActivityIndicatorView(isAnimating: true, style: .medium, color: .gray)
                            .padding(.leading, 16)
                            .frame(height: 33)
                    } else {
                        Text(viewModel.totalFiatValueString)
                            .lineLimit(1)
                            .font(Font.system(size: 28, weight: .semibold))
                            .foregroundColor(Color.tangemGrayDark6)
                            .padding(.leading, 16)
                            .frame(height: 33)
                    }
                    Spacer()
                }
                .padding(.bottom, viewModel.isFailed ? 0 : 16)
                
                HStack(spacing: 0) {
                    if viewModel.isFailed {
                        Text(viewModel.isFailed ? "main_processing_full_amount".localized : "")
                            .foregroundColor(Color.tangemWarning)
                            .font(.system(size: 13, weight: .regular))
                            .padding(.top, 2)
                            .padding([.bottom, .leading], 16)
                    }
                    
                    Spacer()
                }
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
