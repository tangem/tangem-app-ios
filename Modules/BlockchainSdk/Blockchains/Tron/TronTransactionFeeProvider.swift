//
//  TronTransactionFeeProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol TronTransactionFeeProvider {
    /// Non-nil `callData` prices a smart-contract call — `amount` must then be coin-typed, its value
    /// becomes the TRX `call_value`. `nil` prices a plain transfer of `amount`.
    func getFee(amount: Amount, destination: String, callData: Data?, memo: String?) async throws -> [Fee]
}
