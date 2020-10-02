//
//  BalanceView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct BalanceView: View {
    var balanceViewModel: BalanceViewModel
    
    var blockchainText: String {
        if balanceViewModel.loadingError != nil {
            return "balanceView_blockchain_unreachable".localized
        }
        
        if balanceViewModel.hasTransactionInProgress {
            return  "pendingTxView_unknown".localized
        }
        
        return "balanceView_blockchain_verified".localized
    }
    
    
    var accentColor: Color {
        if balanceViewModel.loadingError == nil && !balanceViewModel.hasTransactionInProgress {
            return .tangemTapGreen
        }
        return .tangemTapWarning
    }
    
    var body: some View {
        VStack(spacing: 8.0) {
            VStack {
                if balanceViewModel.isToken {
                    HStack {
                        Text("balanceView_token_title")
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .foregroundColor(Color.tangemTapGrayDark)
                        Spacer()
                    }
                    .padding(.horizontal, 24.0)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(balanceViewModel.name)
                        .font(Font.system(size: 20.0, weight: .bold, design: .default))
                        .minimumScaleFactor(0.4)
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .lineLimit(1)
                    Spacer()
                    Text(balanceViewModel.balance)
                        .font(Font.system(size: 20.0, weight: .bold, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .padding(.horizontal, 23.0)
            }
            .padding(.top, 16.0)
            HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                Image(balanceViewModel.loadingError == nil && !balanceViewModel.hasTransactionInProgress ? "checkmark.circle" : "exclamationmark.circle" )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(accentColor)
                    .frame(width: 10.0, height: 10.0)
                    //.offset(x: 1)
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                VStack(alignment: .leading) {
                    Text(blockchainText)
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .foregroundColor(accentColor)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    if balanceViewModel.loadingError != nil {
                        Text(balanceViewModel.loadingError!)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(accentColor)
                            
                    }
                }
                Spacer()
                Text(balanceViewModel.fiatBalance)
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .foregroundColor(Color.tangemTapGrayDark)
            }
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)
            if balanceViewModel.isToken {
                VStack {
                    Color.tangemTapGrayLight5
                        .frame(width: nil, height: 1.0, alignment: .center)
                        .padding(.bottom, 4.0)
                    HStack(alignment: .firstTextBaseline) {
                        Text(balanceViewModel.secondaryName)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.tangemTapGrayDark6)
                            .lineLimit(1)
                        Spacer()
                        Text(balanceViewModel.secondaryBalance)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                        
                    }
                    HStack {
                        Spacer()
                        Text(balanceViewModel.secondaryFiatBalance)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                            .foregroundColor(Color.tangemTapGrayDark)
                    }
                }
                .padding(.horizontal, 24.0)
                .padding(.bottom, 14.0)
            }
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.tangemTapBgGray
                BalanceView(balanceViewModel: BalanceViewModel(isToken: false,
                                                               hasTransactionInProgress: false,
                                                               loadingError: nil,
                                                               name: "Bitcoin",
                                                               fiatBalance: "$3.45",
                                                               balance: "0.00000348573986753845001 BTC",
                                                               secondaryBalance: "", secondaryFiatBalance: "",
                                                               secondaryName: ""))
            }
            ZStack {
                Color.tangemTapBgGray
                BalanceView(balanceViewModel: BalanceViewModel(isToken: false,
                                                               hasTransactionInProgress: false,
                                                               loadingError: "The internet connection appears to be offline",
                                                               name: "Bitcoin token",
                                                               fiatBalance: " ",
                                                               balance: "-",
                                                               secondaryBalance: "-",
                                                               secondaryFiatBalance: " ",
                                                               secondaryName: "Bitcoin"))
            }
            ZStack {
                Color.tangemTapBgGray
                BalanceView(balanceViewModel: BalanceViewModel(isToken: true,
                                                               hasTransactionInProgress: true,
                                                               loadingError: nil,
                                                               name: "Bitcoin token",
                                                               fiatBalance: "5 USD",
                                                               balance: "10 BTCA",
                                                               secondaryBalance: "19 BTC",
                                                               secondaryFiatBalance: "10 USD",
                                                               secondaryName: "Bitcoin"))
            }
        }
    }
}
