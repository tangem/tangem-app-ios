//
//  Solana+.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

extension SolanaError: Equatable {
    public static func == (lhs: SolanaSwift.SolanaError, rhs: SolanaSwift.SolanaError) -> Bool {
        switch (lhs, rhs) {
        case (.other(let message1), .other(let message2)):
            return message1 == message2
        default:
            return false
        }
    }
}
