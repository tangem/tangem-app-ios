//
//  TokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct TokensView: View {
    var items: [TokenItemViewModel]
    
    var action: (TokenItemViewModel) -> ()
    
    var body: some View {
        Group {
            if items.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("main_tokens".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.tangemTextGray)
                        .padding(.leading, 16)
                        .padding(.top, 14)
                    
                    ForEach(items) { item in
                        Button {
                            ImpactGenerator.generate(.light)
                            action(item)
                        } label: {
                            VStack(spacing: 0) {
                                TokenItemView(item: item)
                                    .padding(.horizontal, 16)
                                    .padding([.top, .bottom], 15)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if items.firstIndex(of: item) != items.count - 1 {
                            Separator(height: 1, padding: 0, separatorColor: Color.tangemBgGray2)
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding([.leading, .trailing], 16)
            }
        }
    }
}

struct TokenItemView: View {
    let item: TokenItemViewModel
    
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
            TokenIconView(with: item.amountType, blockchain: item.blockchainNetwork.blockchain)
                .saturation(item.isTestnet ? 0.0 : 1.0)
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
    }
}

struct TokensView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            TokensView(items: [
                TokenItemViewModel(state: .idle, hasTransactionInProgress: false,
                                   name: "Ethereum ",
                                   fiatBalance: "$3.45",
                                   balance: "0.00000348501 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .idle, hasTransactionInProgress: false,
                                   name: "Ethereum ",
                                   fiatBalance: "$100500222.33",
                                   balance: "0.00000348501 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: true),
                TokenItemViewModel(state: .loading, hasTransactionInProgress: false,
                                   name: "Ethereum smart contract token",
                                   fiatBalance: "$3.45",
                                   balance: "0.00000348573986753845001 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .failed(error: "The internet connection appears to be offline. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description"), hasTransactionInProgress: false,
                                   name: "Ethereum smart contract token",
                                   fiatBalance: " ",
                                   balance: " ",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .idle, hasTransactionInProgress: true,
                                   name: "Bitcoin token",
                                   fiatBalance: "5 USD",
                                   balance: "10 BTCA",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false)
            ], action: { _ in })
        }
    }
}
