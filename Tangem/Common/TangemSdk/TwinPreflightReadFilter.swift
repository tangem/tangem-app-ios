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
    private let twinKey: TwinKey

    init(twinKey: TwinKey) {
        self.twinKey = twinKey
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard let firstPublicKey = card.wallets.first?.publicKey,
              firstPublicKey == twinKey.key1 || firstPublicKey == twinKey.key2 else {
            throw TangemSdkError.walletNotFound
        }
    }
}
