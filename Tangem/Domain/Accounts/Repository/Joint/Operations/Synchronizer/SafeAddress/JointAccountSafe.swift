//
//  JointAccountSafe.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountSafe: Hashable {
    let cryptoAccountId: String
    let safeAddress: String

    init(cryptoAccountId: String, safeAddress: String) {
        self.cryptoAccountId = cryptoAccountId
        self.safeAddress = safeAddress.lowercased()
    }
}

// MARK: - Convenience

extension JointAccountSafe {
    init?(cryptoAccountId: String, status: JointAccountStatus) {
        guard let safeAddress = status.activeSafeAddress else {
            return nil
        }

        self.init(cryptoAccountId: cryptoAccountId, safeAddress: safeAddress)
    }
}
