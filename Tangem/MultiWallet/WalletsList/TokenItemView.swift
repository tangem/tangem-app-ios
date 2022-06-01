//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    let item: TokenItemViewModel
    var isLoading: Bool
    
    private var secondaryText: String {
        if item.state.isNoAccount {
            return item.rate.isEmpty ? "token_item_no_rate".localized : item.rate
        }
        if item.state.isBlockchainUnreachable {
            return "wallet_balance_blockchain_unreachable".localized
        }
        
        if item.hasTransactionInProgress {
            return  "wallet_balance_tx_in_progress".localized
        }
        
        if item.state.isLoading {
            return "wallet_balance_loading".localized
        }
        
        return item.rate
    }
    
    private var balance: String {
        return item.balance.isEmpty ? Decimal(0).currencyFormatted(code: item.currencySymbol) : item.balance
    }
    
    private var accentColor: Color {
        if item.state.failureDescription != nil {
            return .tangemWarning
        }
        return .tangemGrayDark
    }
    
    var body: some View {
        HStack(alignment: .center) {
            TokenIconView(with: item.amountType, blockchain: item.blockchainNetwork.blockchain)
                .saturation(item.isTestnet ? 0.0 : 1.0)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .layoutPriority(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .skeletonable(isShown: isLoading, size: CGSize(width: 70, height: 11))
                    
                    Spacer()
                    
                    Text(item.state.errorDescription != nil ? "—" : item.fiatBalance)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.trailing)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                        .skeletonable(isShown: isLoading, size: CGSize(width: 50, height: 11))
                }
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(.tangemGrayDark6)
                
                
                HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                    if item.isCustom {
                        CustomTokenBadge()
                            .padding(.top, 4)
                    } else {
                        Text(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                            .skeletonable(isShown: isLoading, size: CGSize(width: 50, height: 11))
                    }
                    
                    Spacer()
                    
                    Text(item.state.failureDescription != nil ? "—" : balance)
                        .lineLimit(1)
                        .fixedSize()
                        .skeletonable(isShown: isLoading, size: CGSize(width: 50, height: 11))
                }
                .font(.system(size: 13, weight: .regular))
                .frame(minHeight: 20)
                .foregroundColor(accentColor)
            }
        }
    }
}
