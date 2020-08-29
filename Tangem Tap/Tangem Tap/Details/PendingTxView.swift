//
//  PendingTxView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct PendingTxView: View {
    enum State {
        case incoming
        case outgoing
    }
    
    var txState: State
    var amount: String
    var address: String
    
    var titleFormatKey: String {
        switch txState {
        case .outgoing:
            return "pendingTxView_sending_format"
        case .incoming:
            return "pendingTxView_receiving_format"
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8.0) {
                Image(self.txState == .incoming ?  "arrow.down" :
                    "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .frame(width: 12.0, height: 12.0)
                Text(String(format: NSLocalizedString(titleFormatKey, comment: ""), amount, AddressFormatter(address: address).truncated()))
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, 11.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct PendingTxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            PendingTxView(txState: .incoming, amount: "0.2 BTC", address: "0x12347218734560238o4756023478523452345")
        }
    }
}
