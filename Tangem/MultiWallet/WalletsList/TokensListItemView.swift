//
//  TokensListItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TokensListItemView: View {
    var item: TokenItemViewModel
    
    var secondaryText: String {
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
    
    var accentColor: Color {
        if item.state.errorDescription == nil
            && !item.hasTransactionInProgress
            && !item.state.isLoading {
            return .tangemGrayDark
        }
        return .tangemWarning
    }
    
    var body: some View {
        HStack(alignment: .center) {
            TokenIconView(with: item.amountType, blockchain: item.blockchain)
                .saturation(item.isTestnet ? 0.0 : 1.0)
                .frame(width: 40, height: 40, alignment: .center)
                .id(UUID())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .layoutPriority(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text(item.balance)
                        .multilineTextAlignment(.trailing)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(Color.tangemGrayDark6)
                .font(Font.system(size: 17.0, weight: .medium, design: .default))
                
                
                HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                    if item.state.errorDescription != nil  || item.hasTransactionInProgress {
                        Image(systemName: "exclamationmark.circle" )
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10.0, height: 10.0)
                    }
                    Text(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                    Spacer()
                    Text(item.fiatBalance)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        .foregroundColor(Color.tangemGrayDark)
                }
                .frame(minHeight: 20)
                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                .foregroundColor(accentColor)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(6.0)
        .shadow(color: .tangemGrayLight5, radius: 2, x: 0, y: 1)
    }
}


struct WalletsViewItem_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            VStack {
                TokensListItemView(item: TokenItemViewModel(state: .idle, hasTransactionInProgress: false,
                                                            name: "Ethereum ",
                                                            fiatBalance: "$3.45",
                                                            balance: "0.00000348501 BTC",
                                                            rate: "1.5 USD",
                                                            amountType: .coin,
                                                            blockchain: .ethereum(testnet: false),
                                                            fiatValue: 0))
                    .padding(.horizontal, 16)
                
                TokensListItemView(item: TokenItemViewModel(state: .idle, hasTransactionInProgress: false,
                                                            name: "Ethereum ",
                                                            fiatBalance: "",
                                                            balance: "",
                                                            rate: "",
                                                            amountType: .coin,
                                                            blockchain: .ethereum(testnet: false),
                                                            fiatValue: 0))
                    .padding(.horizontal, 16)
                
                TokensListItemView(item: TokenItemViewModel(
                                    state: .loading, hasTransactionInProgress: false,
                                    name: "Ethereum smart contract token",
                                    fiatBalance: "$3.45",
                                    balance: "0.00000348573986753845001 BTC",
                                    rate: "1.5 USD",
                                    amountType: .coin,
                                    blockchain: .ethereum(testnet: false),
                                    fiatValue: 0))
                    .padding(.horizontal, 16)
                
                TokensListItemView(item: TokenItemViewModel(
                                    state: .failed(error: "The internet connection appears to be offline. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description"), hasTransactionInProgress: false,
                                    name: "Ethereum smart contract token",
                                    fiatBalance: " ",
                                    balance: " ",
                                    rate: "1.5 USD",
                                    amountType: .coin,
                                    blockchain: .ethereum(testnet: false),
                                    fiatValue: 0))
                    .padding(.horizontal, 16)
                
                TokensListItemView(item: TokenItemViewModel(
                                    state: .idle, hasTransactionInProgress: true,
                                    name: "Bitcoin token",
                                    fiatBalance: "5 USD",
                                    balance: "10 BTCA",
                                    rate: "1.5 USD",
                                    amountType: .coin,
                                    blockchain: .ethereum(testnet: false),
                                    fiatValue: 0))
                    .padding(.horizontal, 16)
            }
        }
    }
}
