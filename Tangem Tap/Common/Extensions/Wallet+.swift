//
//  Wallet+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

extension Wallet {
    var incomingTransactions: [BlockchainSdk.Transaction] {
        return transactions.filter { $0.destinationAddress == address
            && $0.status == .unconfirmed
            && $0.sourceAddress != "unknown"
        }
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        return transactions.filter { $0.sourceAddress == address
            && $0.status == .unconfirmed
            && $0.destinationAddress != "unknown"
        }
    }
    
    public var canSend: Bool {
        if hasPendingTx {
            return false
        }
        
        if amounts.isEmpty { //not loaded from blockchain
            return false
        }
        
        if amounts.values.first(where: { $0.value > 0 }) == nil { //empty wallet
            return false
        }
        
        let coinAmount = amounts[.coin]?.value ?? 0
        if coinAmount <= 0 { //not enough fee
            return false
        }
        
        return true
    }
    
    @ViewBuilder func getImageView(for amountType: Amount.AmountType) -> some View {
        if amountType == .coin, let name = blockchain.imageName {
            Image(name)
        } else if let token = amountType.token {
            CircleImageTextView(name: token.name, color: token.color)
        } else {
            CircleImageTextView(name: blockchain.displayName,
                            color: Color.tangemTapGrayLight4)
        }
    }
}
