//
//  ExpressPendingTransactionRecord+Related.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

extension ExpressPendingTransactionRecord {
    func isRelated(to userWalletId: UserWalletId, tokenItem: TokenItem) -> Bool {
        guard !isHidden else {
            return false
        }

        // We should show only `supportStatusTracking` transaction on UI
        guard provider.type.supportStatusTracking else {
            return false
        }

        let isSourceWallet = userWalletId.stringValue == sourceTokenTxInfo.userWalletId
        // In the send with swap flow the destination is a plain address, so the receiving wallet is unknown
        let isDestinationWallet = userWalletId.stringValue == (destinationTokenTxInfo.userWalletId ?? sourceTokenTxInfo.userWalletId)

        let isSourceToken = tokenItem == sourceTokenTxInfo.tokenItem
        let isDestinationToken = tokenItem == destinationTokenTxInfo.tokenItem

        let isRelatedSource = isSourceWallet && isSourceToken
        let isRelatedDestination = isDestinationWallet && isDestinationToken

        return isRelatedSource || isRelatedDestination
    }
}
