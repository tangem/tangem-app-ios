//
//  PolkadotAccountHealthNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol PolkadotAccountHealthNetworkService {
    func getAccountHealthInfo(account: String) async throws -> PolkadotAccountHealthInfo
    func getTransactionsList(account: String, afterId: Int) async throws -> [PolkadotTransaction]
    func getTransactionDetails(hash: String) async throws -> PolkadotTransactionDetails
}

// MARK: - Dependency injection

extension InjectedValues {
    private struct PolkadotAccountHealthNetworkServiceKey: InjectionKey {
        static var currentValue: PolkadotAccountHealthNetworkService = SubscanPolkadotAccountHealthNetworkService(isTestnet: false)
    }

    var polkadotAccountHealthNetworkService: PolkadotAccountHealthNetworkService {
        get { Self[PolkadotAccountHealthNetworkServiceKey.self] }
        set { Self[PolkadotAccountHealthNetworkServiceKey.self] = newValue }
    }
}

// MARK: - PolkadotAccountHealthNetworkService protocol conformance

extension SubscanPolkadotAccountHealthNetworkService: PolkadotAccountHealthNetworkService {}
