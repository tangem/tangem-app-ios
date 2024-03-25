//
//  BlockchainAnalytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct BlockchainAnalytics: BlockchainSdk.BlockchainAnalytics {
    func logPolkadotAccountHasBeenResetEvent(value: Bool) {
        let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
        Analytics.log(event: .healthCheckPolkadotAccountReset, params: [.state: value.rawValue])
    }

    func logPolkadotAccountHasImmortalTransactions(value: Bool) {
        let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
        Analytics.log(event: .healthCheckPolkadotImmortalTransactions, params: [.state: value.rawValue])
    }
}
