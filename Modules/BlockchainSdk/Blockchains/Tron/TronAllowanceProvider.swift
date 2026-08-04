//
//  TronAllowanceProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol TronAllowanceProvider {
    /// Returns the raw (non-normalized) TRC20 allowance value.
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
}
