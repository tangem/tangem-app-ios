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
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("main_tokens".localized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 6)

                ForEach(items) { item in
                    Button {
                        action(item)
                    } label: {
                        TokenItemView(item: item)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(TangemTokenButtonStyle())

                    if items.firstIndex(of: item) != items.count - 1 {
                        Separator(height: 1, padding: 0, color: Color.tangemBgGray2)
                            .padding(.leading, 68)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
}

struct TokensView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            TokensView(items: [
                TokenItemViewModel(state: .idle, displayState: .readyForDisplay,
                                   hasTransactionInProgress: false,
                                   name: "Ethereum ",
                                   fiatBalance: "$3.45",
                                   balance: "0.00000348501 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .idle, displayState: .readyForDisplay,
                                   hasTransactionInProgress: false,
                                   name: "Ethereum ",
                                   fiatBalance: "$100500222.33",
                                   balance: "0.00000348501 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: true),
                TokenItemViewModel(state: .loading, displayState: .readyForDisplay,
                                   hasTransactionInProgress: false,
                                   name: "Ethereum smart contract token",
                                   fiatBalance: "$3.45",
                                   balance: "0.00000348573986753845001 BTC",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .failed(error: "The internet connection appears to be offline. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description"), displayState: .readyForDisplay, hasTransactionInProgress: false,
                                   name: "Ethereum smart contract token",
                                   fiatBalance: " ",
                                   balance: " ",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
                TokenItemViewModel(state: .idle, displayState: .readyForDisplay,
                                   hasTransactionInProgress: true,
                                   name: "Bitcoin token",
                                   fiatBalance: "5 USD",
                                   balance: "10 BTCA",
                                   rate: "1.5 USD",
                                   amountType: .coin,
                                   blockchainNetwork: .init(.ethereum(testnet: false)),
                                   fiatValue: 0,
                                   isCustom: false),
            ], action: { _ in })
        }
    }
}
