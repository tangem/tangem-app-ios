//
//  Wallet.PublicKey+.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk

extension Wallet.PublicKey {
    static let empty = Wallet.PublicKey(seedKey: Data(), derivationType: .none)
}
