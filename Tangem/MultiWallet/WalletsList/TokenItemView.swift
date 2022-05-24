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
        if item.state.errorDescription == nil
            && !item.hasTransactionInProgress
            && !item.state.isLoading {
            return .tangemGrayDark
        }
        return .tangemWarning
    }
    
    var body: some View {
        HStack(alignment: .center) {
            TokenIconView(with: item.amountType, blockchain: item.blockchainNetwork.blockchain)
                .saturation(item.isTestnet ? 0.0 : 1.0)
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .layoutPriority(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    if item.state.errorDescription != nil {
                        Rectangle()
                            .frame(width: 10, height: 1)
                            .padding(.bottom, 4)
                    } else {
                        Text(item.fiatBalance)
                            .font(.system(size: 13, weight: .regular))
                            .multilineTextAlignment(.trailing)
                            .truncationMode(.middle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(Color.tangemGrayDark6)
                
                
                HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                    if item.isCustom {
                        CustomTokenBadge()
                            .layoutPriority(-1)
                    } else {
                        Text(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    if item.state.mainPageErrorDescription != nil {
                        Rectangle()
                            .frame(width: 10, height: 1)
                            .padding(.bottom, 4)
                    } else {
                        Text(balance)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 13, weight: .regular))
                .frame(minHeight: 20)
                .foregroundColor(.tangemTextGray)
            }
        }
    }
}

/*
 item.balance -> 1,00 SOL
 item.fiatBalance -> 49,64 US$
 item.name -> Solana
 secondaryText -> 49,64 US$
*/
