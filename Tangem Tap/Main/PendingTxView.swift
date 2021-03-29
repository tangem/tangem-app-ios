//
//  PendingTxView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct PendingTxView: View, Identifiable {
    
    enum State {
        case incoming
        case outgoing
    }
    
    var id = UUID()
    var txState: State
    var amount: String
    var address: String
    
    
    var titlePrefixLocalized: String {
           switch txState {
           case .outgoing:
               return "wallet_pending_tx_sending".localized
           case .incoming:
               return "wallet_pending_tx_receiving".localized
           }
       }
    
    var titleFormat: String {
        switch txState {
        case .outgoing:
            return "wallet_pending_tx_sending_address_format".localized
        case .incoming:
            return "wallet_pending_tx_receiving_address_format".localized
        }
    }
    
    var text: String {
        if address == "unknown" {
            return "wallet_balance_tx_in_progress".localized
        } else {
            return titlePrefixLocalized + amount.description + String(format: titleFormat, AddressFormatter(address: address).truncated())
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8.0) {
                if address != "unknown" {
                Image(self.txState == .incoming ?  "arrow.down" :
                    "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .frame(width: 12.0, height: 12.0)
                }
                Text(text)
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
    }
}

struct PendingTxView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            PendingTxView(txState: .outgoing, amount: "0.2 BTC", address: "sadfasdfasdfsadf")
        }
    }
}
