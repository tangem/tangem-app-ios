//
//  StakeKitTransactionDataBroadcaster.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

/// Low-level protocol for sending singed transaction data to blockchain
protocol StakeKitTransactionDataBroadcaster {
    associatedtype RawTransaction

    /// Send raw transaction data into blockchain
    /// - Parameters:
    ///   - transaction: original unsigned transaction from StakeKit
    ///   - rawTransaction: signed transaction data
    /// - Returns: hash of the submitted transaction
    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String
}
