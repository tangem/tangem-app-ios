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
            return "wallet_error_no_account".localized
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
                    
                    Text(item.fiatBalance)
                        .font(.system(size: 13, weight: .regular))
                        .multilineTextAlignment(.trailing)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(Color.tangemGrayDark6)
                
                
                HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                    if item.state.errorDescription != nil  || item.hasTransactionInProgress {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10.0, height: 10.0)
                    }
                    if item.isCustom {
                        CustomTokenBadge()
                            .layoutPriority(-1)
                    } else {
                        Text(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(item.balance)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        .foregroundColor(Color.tangemGrayDark)
                }
                .font(.system(size: 13, weight: .regular))
                .frame(minHeight: 20)
                .foregroundColor(accentColor)
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
