//
//  GaslessTransactionSendResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct GaslessTransactionSendResult: Hashable {
    public let hash: String
    public let currentProviderHost: String

    public init(hash: String, currentProviderHost: String) {
        self.hash = hash
        self.currentProviderHost = currentProviderHost
    }
}
