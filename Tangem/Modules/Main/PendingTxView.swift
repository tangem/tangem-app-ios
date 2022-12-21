//
//  PendingTxView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct PendingTxView: View, Identifiable {

    var id: Int { pendingTx.id }
    let pendingTx: PendingTransaction
    var pushAction: (() -> Void)? = nil

    var address: String {
        pendingTx.destination
    }

    var titlePrefixLocalized: String {
        switch pendingTx.direction {
        case .outgoing:
            return L10n.walletPendingTxSending
        case .incoming:
            return L10n.walletPendingTxReceiving
        }
    }

    func titleFormat(address: String) -> String {
        switch pendingTx.direction {
        case .outgoing:
            return L10n.walletPendingTxSendingAddressFormat(address)
        case .incoming:
            return L10n.walletPendingTxReceivingAddressFormat(address)
        }
    }

    var text: String {
        if address == "unknown" {
            return L10n.walletBalanceTxInProgress
        } else {
            return titlePrefixLocalized + " " + pendingTx.transferAmount + " " + titleFormat(address: AddressFormatter(address: address).truncated())
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                if address != "unknown" {
                    Image(systemName: self.pendingTx.direction == .incoming ?  "arrow.down" :
                        "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.tangemGrayDark6)
                        .frame(width: 12.0, height: 12.0)
                        .padding(.trailing, 8)
                }

                Text(text)
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemGrayDark6)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if pendingTx.canBePushed {
                    RoundedRectButton(action: {
                        pushAction?()
                    }, title: L10n.commonPush)
                }
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
            Color.tangemBgGray
            VStack {
                PendingTxView(pendingTx: PendingTransaction(amountType: .coin, destination: "0x2314719083467891237649123675478612354", transferAmount: "0.00000002 BTC", canBePushed: false, direction: .incoming))
                PendingTxView(pendingTx: PendingTransaction(amountType: .coin, destination: "0x2314719083467891237649123675478612354", transferAmount: "0.00000002 BTC", canBePushed: false, direction: .outgoing))
                PendingTxView(pendingTx: PendingTransaction(amountType: .coin, destination: "0x2314719083467891237649123675478612354", transferAmount: "0.2 BTC", canBePushed: true, direction: .outgoing))
            }
            .padding(.horizontal, 16)

        }
    }
}
