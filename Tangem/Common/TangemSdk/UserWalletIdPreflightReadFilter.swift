//
//  UserWalletIdPreflightReadFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct UserWalletIdPreflightReadFilter: PreflightReadFilter {
    private let expectedUserWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        expectedUserWalletId = userWalletId
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard let firstPublicKey = card.wallets.first?.publicKey else {
            return
        }

        let userWalletId = UserWalletId(with: firstPublicKey)
        if userWalletId != expectedUserWalletId {
            throw TangemSdkError.walletNotFound
        }
    }
}
