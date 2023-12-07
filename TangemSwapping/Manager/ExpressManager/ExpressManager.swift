//
//  ExpressManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol ExpressManager {
    func getPair() async -> ExpressManagerSwappingPair?
    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState

    func getAmount() async -> Decimal?
    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState

    func getAllQuotes() async -> [ExpectedQuote]
    func getSelectedQuote() async -> ExpectedQuote?
    func updateSelectedProvider(provider: ExpressProvider) async throws -> ExpressManagerState

    func update() async throws -> ExpressManagerState

    func didSentAllowanceTransaction(for spender: String) async
    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}
