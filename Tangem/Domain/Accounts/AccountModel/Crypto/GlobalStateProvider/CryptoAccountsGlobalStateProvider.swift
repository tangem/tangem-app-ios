//
//  CryptoAccountsGlobalStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CryptoAccountsGlobalStateProvider {
    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable
    func unregister<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable

    func globalCryptoAccountsStatePublisher() -> AnyPublisher<CryptoAccounts.State, Never>
    func globalCryptoAccountsState() -> CryptoAccounts.State
}

// MARK: - Auxiliary types

@available(iOS, deprecated: 100000.0, message: "Temporary logger for troubleshooting, will be removed in future ([REDACTED_INFO])")
let CryptoAccountsGlobalStateProviderLogger = AccountsLogger.tag(#fileID)
