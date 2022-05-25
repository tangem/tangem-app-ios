//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import SkeletonUI

struct TotalSumBalanceView: View {
    @ObservedObject var viewModel: TotalSumBalanceViewModel
    
    var tapOnCurrencySymbol: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("main_page_balance".localized)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                
                Spacer()
                
                Button {
                    tapOnCurrencySymbol()
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.currencyType)
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .medium))
                        Image("tangemArrowDown")
                    }
                    .foregroundColor(Color.tangemLightGray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)
            
            if viewModel.isFailed {
                Rectangle()
                    .foregroundColor(Color.tangemGrayDark6)
                    .frame(width: 15, height: 1)
                    .padding(.vertical, 16)
            } else {
                Text(viewModel.totalFiatValueString)
                    .font(.system(size: 28, weight: .semibold))
                    .skeleton(with: viewModel.isLoading, size: CGSize(width: 100, height: 25), animated: .default)
                    .shape(type: .rounded(.radius(3, style: .circular)))
                    .animation(type: .linear())
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
        .padding(16)
        .background(Color.white)
        .onDisappear {
            viewModel.disableLoading()
        }
    }
}
