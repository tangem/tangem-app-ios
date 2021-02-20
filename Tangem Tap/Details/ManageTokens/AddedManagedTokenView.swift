//
//  AddedManagedTokenView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct AddedManagedTokenView: View {
    
    var token: TokenBalanceViewModel
    var removeTokenAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(token.name)
                    .font(.system(size: 17, weight: .medium))
                Text(token.balance)
                    .font(.system(size: 14, weight: .regular))
            }
            Spacer()
            TangemButton(isLoading: false, title: "common_remove", image: "", size: .thinHorizontal, action: removeTokenAction)
                .buttonStyle(TangemButtonStyle(color: .gray, isDisabled: false))
        }
        .background(Color.white)
        
    }
}

struct TrustedManagedTokenView_Previews: PreviewProvider {
    static var previews: some View {
        AddedManagedTokenView(token: TokenBalanceViewModel(token: Token(name: "SushiSwap", symbol: "SUSHI", contractAddress: "", decimalCount: 18), balance: "163.7425436", fiatBalance: "$ 2241.31"), removeTokenAction: { })
    }
}
