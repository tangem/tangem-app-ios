//
//  ALPH+TransactionId.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension ALPH {
    struct TransactionId {
        let value: ALPH.Blake2b

        static func hash(bytes: Data) -> TransactionId {
            TransactionId(value: ALPH.Blake2b.hash(bytes))
        }
    }
}
