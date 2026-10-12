//
//  TangemPayRecentOperation.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayRecentOperation: Codable, Equatable {
    let from: Side
    let to: Side
    let date: Date

    var direction: Direction {
        from.isPaymentAccount ? .outgoing : .incoming
    }

    var paymentAccountSide: Side {
        switch direction {
        case .outgoing: from
        case .incoming: to
        }
    }

    var counterpartSide: Side {
        switch direction {
        case .outgoing: to
        case .incoming: from
        }
    }

    var repeatKey: String {
        [
            WalletModelId(tokenItem: paymentAccountSide.tokenItem).id,
            counterpartSide.userWalletId,
            WalletModelId(tokenItem: counterpartSide.tokenItem).id,
        ].joined(separator: "|")
    }
}

// MARK: - Side

extension TangemPayRecentOperation {
    struct Side: Codable, Equatable {
        let userWalletId: String
        let tokenItem: TokenItem
        let isPaymentAccount: Bool
    }
}

// MARK: - Direction

extension TangemPayRecentOperation {
    enum Direction {
        case outgoing
        case incoming
    }
}
