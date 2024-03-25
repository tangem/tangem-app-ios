//
//  FakeBlockchainAnalytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct FakeBlockchainAnalytics: BlockchainSdk.BlockchainAnalytics {
    func logPolkadotAccountHasBeenResetEvent(value: Bool) {
        print("\(#function) == \(value)")
    }

    func logPolkadotAccountHasImmortalTransactions(value: Bool) {
        print("\(#function) == \(value)")
    }
}
