//
//  ALPH+TokenId.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// Represents a token ID, which is a wrapper around a `Hash`.
    struct TokenId: Hashable {
        let value: Data
    }
}
