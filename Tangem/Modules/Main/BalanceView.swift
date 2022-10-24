//
//  BalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk

struct TokenBalanceView: View {
    var tokenViewModel: TokenBalanceViewModel

    var body: some View {
        VStack {
            HStack {
                Text(tokenViewModel.name)
                Spacer()
                Text(tokenViewModel.balance)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.tangemGrayDark6)
            .padding(.bottom, 2)
            HStack {
                Spacer()
                Text(tokenViewModel.fiatBalance)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tangemGrayDark)
            }
        }
        .padding(8)
        .background(Color.tangemGrayLight6)
        .cornerRadius(6)
    }
}

struct BalanceView: View {
    var balanceViewModel: BalanceViewModel
    var tokenBalanceViewModels: [TokenBalanceViewModel]

    var blockchainText: String {
        if balanceViewModel.state.isLoading {
            return  "wallet_balance_loading".localized
        }

        if balanceViewModel.state.errorDescription != nil {
            return "wallet_balance_blockchain_unreachable".localized
        }

        if balanceViewModel.hasTransactionInProgress {
            return  "wallet_balance_tx_in_progress".localized
        }

        return "wallet_balance_verified".localized
    }

    var accentColor: Color {
        if balanceViewModel.state.errorDescription == nil
            && !balanceViewModel.hasTransactionInProgress
            && !balanceViewModel.state.isLoading {
            return .tangemGreen
        }
        return .tangemWarning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Color.clear.frame(height: 16)

            HStack {
                Text(balanceViewModel.name)
                Spacer()
                Text(balanceViewModel.fiatBalance)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.middle)
            }
            .font(Font.system(size: 20.0, weight: .bold, design: .default))
            .foregroundColor(Color.tangemGrayDark6)
            .minimumScaleFactor(0.8)
            .lineLimit(2)
            .padding(.horizontal, 24.0)
            .padding(.bottom, 8)
            .fixedSize(horizontal: false, vertical: true)


            HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                Image(systemName: balanceViewModel.state.errorDescription == nil && !balanceViewModel.hasTransactionInProgress ? "checkmark.circle" : "exclamationmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(accentColor)
                    .frame(width: 10.0, height: 10.0)
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                VStack(alignment: .leading) {
                    Text(blockchainText)
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                    if balanceViewModel.state.errorDescription != nil {
                        Text(balanceViewModel.state.errorDescription!)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Text(balanceViewModel.balanceFormatted)
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    .lineLimit(1)
                    .foregroundColor(Color.tangemGrayDark)
            }
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)


            if balanceViewModel.isToken {
                Color.tangemGrayLight5
                    .frame(width: nil, height: 1.0, alignment: .center)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 24.0)
                HStack(alignment: .firstTextBaseline) {
                    Text(balanceViewModel.secondaryName)
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .foregroundColor(Color.tangemGrayDark6)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(balanceViewModel.secondaryBalance)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                            .lineLimit(1)
                        Text(balanceViewModel.secondaryFiatBalance)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .lineLimit(1)
                            .foregroundColor(Color.tangemGrayDark)
                    }

                }
                .padding(.horizontal, 24.0)

                Color.clear.frame(height: 16)
            } else if !tokenBalanceViewModels.isEmpty {
                VStack(spacing: 8) {
                    ForEach(tokenBalanceViewModels, id: \.tokenName) { token in
                        TokenBalanceView(tokenViewModel: token)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(6.0)
    }
}

struct BalanceView_Previews: PreviewProvider {

    static let tokens = [
        TokenBalanceViewModel(token: Token(name: "SushiSwap", symbol: "SUSHI", contractAddress: "", decimalCount: 18),
                              balance: "163.7425436",
                              fiatBalance: "$ 2241.31"),
    ]

    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            VStack {
                BalanceView(balanceViewModel: BalanceViewModel(isToken: false,
                                                               hasTransactionInProgress: false,
                                                               state: .idle,
                                                               name: "Ethereum smart contract token",
                                                               fiatBalance: "$3.45",
                                                               balance: "0.00000348573986753845001 BTC",
                                                               secondaryBalance: "", secondaryFiatBalance: "",
                                                               secondaryName: ""),
                            tokenBalanceViewModels: tokens)
                    .padding(.horizontal, 16)

                BalanceView(balanceViewModel: BalanceViewModel(isToken: false,
                                                               hasTransactionInProgress: false,
                                                               state: .loading,
                                                               name: "Ethereum smart contract token",
                                                               fiatBalance: "$3.45",
                                                               balance: "0.00000348573986753845001 BTC",
                                                               secondaryBalance: "", secondaryFiatBalance: "",
                                                               secondaryName: ""),
                            tokenBalanceViewModels: tokens)
                    .padding(.horizontal, 16)

                BalanceView(balanceViewModel: BalanceViewModel(isToken: true,
                                                               hasTransactionInProgress: false,
                                                               state: .failed(error: "The internet connection appears to be offline. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description"),
                                                               name: "Ethereum smart contract token",
                                                               fiatBalance: " ",
                                                               balance: " ",
                                                               secondaryBalance: " ",
                                                               secondaryFiatBalance: "",
                                                               secondaryName: "Bitcoin"),
                            tokenBalanceViewModels: tokens)
                    .padding(.horizontal, 16)

                BalanceView(balanceViewModel: BalanceViewModel(isToken: true,
                                                               hasTransactionInProgress: true,
                                                               state: .idle,
                                                               name: "Bitcoin token",
                                                               fiatBalance: "5 USD",
                                                               balance: "10 BTCA",
                                                               secondaryBalance: "19 BTC",
                                                               secondaryFiatBalance: "10 USD",
                                                               secondaryName: "Bitcoin"),
                            tokenBalanceViewModels: tokens)
                    .padding(.horizontal, 16)
            }
        }
    }
}
