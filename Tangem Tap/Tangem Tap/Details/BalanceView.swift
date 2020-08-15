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
    var walletModel: WalletModel
    
    var body: some View {
        VStack(spacing: 8.0) {
            VStack {
            if walletModel.isToken {
                HStack {
                    Text("balanceView_token_title")
                        .font(Font.system(size: 11.0))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .foregroundColor(Color.tangemTapDarkGrey)
                    Spacer()
                }
                .padding(.horizontal, 24.0)
            }
            HStack {
                Text(walletModel.name)
                    .font(Font.system(size: 20.0))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color.tangemTapTitle)
                    .lineLimit(1)
                Spacer()
                Text(walletModel.balance)
                    .font(Font.system(size: 20.0))
                    .fontWeight(.bold)
                    .foregroundColor(Color.tangemTapTitle)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
            .padding(.horizontal, 24.0)
            }
            .padding(.top, 16.0)
            HStack(spacing: 5.0) {
                Image(walletModel.dataLoaded ? "checkmark.circle" : "exclamationmark.circle" )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(walletModel.dataLoaded ? Color.tangemTapGreen :
                        Color.tangemTapYellow)
                    .frame(width: 10.0, height: 10.0)
                Text(walletModel.dataLoaded ? "balanceView_blockchain_verified" : "balanceView_blockchain_unreachable")
                    .font(Font.system(size: 11.0))
                    .foregroundColor(walletModel.dataLoaded ? Color.tangemTapGreen :
                        Color.tangemTapYellow)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Spacer()
                Text(walletModel.usdBalance)
                    .font(Font.system(size: 11.0))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .foregroundColor(Color.tangemTapDarkGrey)
            }
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)
            if walletModel.isToken {
                VStack(spacing: 12.0) {
                    Color.tangemTapLightGray
                        .frame(width: nil, height: 1.0, alignment: .center)
                    HStack {
                        Text(walletModel.secondaryName)
                            .font(Font.system(size: 13.0))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.tangemTapTitle)
                            .lineLimit(1)
                        Spacer()
                        Text(walletModel.secondaryBalance)
                            .font(Font.system(size: 11.0))
                            .fontWeight(.bold)
                            .foregroundColor(Color.tangemTapTitle)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
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
        ZStack {
            Color.tangemBg
            BalanceView(walletModel: WalletModel( card: Card.testCard))
        }
    }
}
