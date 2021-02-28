//
//  WalletsViewitem.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk

struct WalletsViewItem: View {
    var item: WalletItemModel
    
    var secondaryText: String {
        if item.loadingError != nil {
            return "wallet_balance_blockchain_unreachable".localized
        }
        
        if item.hasTransactionInProgress {
            return  "wallet_balance_tx_in_progress".localized
        }
        
        if item.isLoading {
            return  "wallet_balance_loading".localized
        }
        
        return item.rate
    }
    
    var image: String {
        item.loadingError == nil
            && !item.hasTransactionInProgress
            && !item.isLoading ? "checkmark.circle" : "exclamationmark.circle"
    }
    
    var accentColor: Color {
        if item.loadingError == nil
            && !item.hasTransactionInProgress
            && !item.isLoading {
            return .tangemTapGrayDark
        }
        return .tangemTapWarning
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Color.clear.frame(height: 16)
            
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(item.balance)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .foregroundColor(Color.tangemTapGrayDark6)
            .font(Font.system(size: 17.0, weight: .medium, design: .default))
            .padding(.horizontal, 24.0)
            .padding(.bottom, 8)
            
            
            HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                if item.loadingError != nil  || item.hasTransactionInProgress {
                    Image("exclamationmark.circle" )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10.0, height: 10.0)
                }
                VStack(alignment: .leading) {
                    Text(secondaryText)
                        .lineLimit(1)
                    if item.loadingError != nil {
                        Text(item.loadingError!)
                            .layoutPriority(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Text(item.fiatBalance)
                    .lineLimit(1)
                    .foregroundColor(Color.tangemTapGrayDark)
            }
            .font(Font.system(size: 14.0, weight: .medium, design: .default))
            .foregroundColor(accentColor)
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
    }
}


struct WalletsViewItem_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            VStack {
                WalletsViewItem(item: WalletItemModel(hasTransactionInProgress: false,
                                                      isLoading: false,
                                                      loadingError: nil,
                                                      name: "Ethereum smart contract token",
                                                      fiatBalance: "$3.45",
                                                      balance: "0.00000348573986753845001 BTC",
                                                      rate: "1.5 USD",
                                                      blockchain: .ethereum(testnet: false)))
                    .padding(.horizontal, 16)
                
                WalletsViewItem(item: WalletItemModel(
                                    hasTransactionInProgress: false,
                                    isLoading: true,
                                    loadingError: nil,
                                    name: "Ethereum smart contract token",
                                    fiatBalance: "$3.45",
                                    balance: "0.00000348573986753845001 BTC",
                                    rate: "1.5 USD",
                                    blockchain: .ethereum(testnet: false)))
                    .padding(.horizontal, 16)
                
                WalletsViewItem(item: WalletItemModel(
                                    hasTransactionInProgress: false,
                                    isLoading: false,
                                    loadingError: "The internet connection appears to be offline",
                                    name: "Ethereum smart contract token",
                                    fiatBalance: " ",
                                    balance: "-",
                                    rate: "1.5 USD",
                                    blockchain: .ethereum(testnet: false)))
                    .padding(.horizontal, 16)
                
                WalletsViewItem(item: WalletItemModel(
                                    hasTransactionInProgress: true,
                                    isLoading: false,
                                    loadingError: nil,
                                    name: "Bitcoin token",
                                    fiatBalance: "5 USD",
                                    balance: "10 BTCA",
                                    rate: "1.5 USD",
                                    blockchain: .ethereum(testnet: false)))
                    .padding(.horizontal, 16)
            }
        }
    }
}
