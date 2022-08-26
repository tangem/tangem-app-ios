//
//  WalletConnectSessionItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectSessionItemView: View {
    var dAppName: String
    var disconnectEvent: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dAppName)
                    .font(.system(size: 17, weight: .medium))
                    .padding(.bottom, 2)
                    .foregroundColor(.tangemGrayDark6)
            }
            Spacer()
            TangemButton(title: "common_disconnect", action: disconnectEvent)
                .buttonStyle(TangemButtonStyle(colorStyle: .gray, layout: .thinHorizontal))
        }
        .padding(.vertical, 12)
    }
}

struct WalletConnectSessionItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletConnectSessionItemView(dAppName: "DAppName 1",
                                     disconnectEvent: { })
    }
}
