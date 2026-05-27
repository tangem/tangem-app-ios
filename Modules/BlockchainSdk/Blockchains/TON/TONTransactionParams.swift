//
//  TONTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore

public struct TONTransactionParams: TransactionParams {
    var memo: String

    public init(memo: String) {
        self.memo = memo
    }
}
