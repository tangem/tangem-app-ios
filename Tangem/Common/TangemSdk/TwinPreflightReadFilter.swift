//
//  TwinPreflightReadFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct TwinPreflightReadFilter: PreflightReadFilter {
    private let expectedUserWalletId: UserWalletId
    private let pairPublicKey: Data

    init(userWalletId: UserWalletId, pairPublicKey: Data) {
        expectedUserWalletId = userWalletId
        self.pairPublicKey = pairPublicKey
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard let firstPublicKey = card.wallets.first?.publicKey,
              let combinedKey = TwinCardsUtils.makeCombinedWalletKey(for: firstPublicKey, pairPublicKey: pairPublicKey) else {
            return
        }

        let userWalletId = UserWalletId(with: combinedKey)
        if userWalletId != expectedUserWalletId {
            throw TangemSdkError.walletNotFound
        }
    }
}
