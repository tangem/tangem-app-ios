//
//  WalletConnectSessionItemView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectSessionItemView: View {
    var dAppName: String
    var cardId: String
    var disconnectEvent: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dAppName)
                    .font(.system(size: 17, weight: .medium))
                    .padding(.bottom, 2)
                    .foregroundColor(.tangemTapGrayDark6)
                Text("Card: " + cardId)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
            }
            Spacer()
            TangemButton(isLoading: false, title: "Disconnect", image: "", size: .thinHorizontal, action: disconnectEvent)
            .buttonStyle(TangemButtonStyle(color: .gray, isDisabled: false))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct WalletConnectSessionItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletConnectSessionItemView(dAppName: "DAppName 1",
                                     cardId: "CB23 4344 5455 6544",
                                     disconnectEvent: { })
    }
}
