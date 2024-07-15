//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yield(integrationId: String) async throws -> YieldInfo
    func balance(address: String, network: String) async throws -> BalanceInfo

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> EnterAction

    func patchTransaction(id: String) async throws -> TransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
}
