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
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .lineLimit(1)
                    Spacer()
                    Text(balanceViewModel.balance)
                         .font(Font.system(size: 20.0, weight: .bold, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, 24.0)
            }
            .padding(.top, 16.0)
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 5.0) {
                    Image(balanceViewModel.dataLoaded ? "checkmark.circle" : "exclamationmark.circle" )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(balanceViewModel.dataLoaded ? Color.tangemTapGreen :
                            Color.tangemTapWarning)
                        .frame(width: 10.0, height: 10.0)
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    Text(balanceViewModel.dataLoaded ? "balanceView_blockchain_verified" : "balanceView_blockchain_unreachable")
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .foregroundColor(balanceViewModel.dataLoaded ? Color.tangemTapGreen :
                            Color.tangemTapWarning)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    Spacer()
                    Text(balanceViewModel.fiatBalance)
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .foregroundColor(Color.tangemTapGrayDark)
                }
                HStack {
                    if !balanceViewModel.dataLoaded && balanceViewModel.loadingError != nil {
                        Text(balanceViewModel.loadingError!)
                           .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(balanceViewModel.dataLoaded ? Color.tangemTapGreen :
                                Color.tangemTapWarning)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .padding(.leading, 15.0)
                    }
                    Spacer()
                }
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
                                                               dataLoaded: true,
                                                               loadingError: nil,
                                                               name: "Bitcoin",
                                                               fiatBalance: "$3.45",
                                                               balance: "0.00000348573986753845001 BTC",
                                                               secondaryBalance: "", secondaryFiatBalance: "",
                                                               secondaryName: ""))
            }
            ZStack {
                Color.tangemTapBgGray
                BalanceView(balanceViewModel: BalanceViewModel(isToken: true,
                                                               dataLoaded: false,
                                                               loadingError: "Something went wrong",
                                                               name: "Bitcoin token",
                                                               fiatBalance: "-",
                                                               balance: "10 BTCA",
                                                               secondaryBalance: "19 BTC",
                                                               secondaryFiatBalance: "-",
                                                               secondaryName: "Bitcoin"))
            }
            ZStack {
                Color.tangemTapBgGray
                BalanceView(balanceViewModel: BalanceViewModel(isToken: true,
                                                               dataLoaded: true,
                                                               loadingError: "Something went wrong",
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
