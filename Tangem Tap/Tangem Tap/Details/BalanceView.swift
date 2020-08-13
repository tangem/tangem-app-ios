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
            HStack {
                Text(walletModel.blockchainName)
                    .font(Font.system(size: 20.0))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Spacer()
                Text(walletModel.balance)
                    .font(Font.system(size: 20.0))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
            .padding(.top, 16.0)
            .padding(.horizontal, 24.0)
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
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceView(walletModel: WalletModel( card: Card.testCard))
    }
}
