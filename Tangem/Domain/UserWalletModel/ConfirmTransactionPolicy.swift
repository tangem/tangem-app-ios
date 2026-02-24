//
//  ConfirmTransactionPolicy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ConfirmTransactionPolicy {
    var needsHoldToConfirm: Bool { get }
}

struct CommonConfirmTransactionPolicy: ConfirmTransactionPolicy {
    let needsHoldToConfirm: Bool

    init(userWalletInfo: UserWalletInfo) {
        needsHoldToConfirm = !userWalletInfo.signer.hasNFCInteraction
    }

    init(dispatcher: TransactionDispatcher) {
        needsHoldToConfirm = !dispatcher.hasNFCInteraction
    }
}
