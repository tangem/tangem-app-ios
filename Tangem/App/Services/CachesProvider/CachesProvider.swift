//
//  CachesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol CachesProviding {
    var tokenBalancesStorage: TokenBalancesStorage { get }
    var yieldModuleStateRepository: YieldModuleStateRepository { get }
    var yieldModuleMarketsRepository: YieldModuleMarketsRepository { get }

    func storage(for file: CachesDirectoryStorage.File) -> CachesDirectoryStorage
}

final class CachesProvider: CachesProviding {
    private let lock = NSLock()
    private var storages: [String: CachesDirectoryStorage] = [:]

    lazy var tokenBalancesStorage: TokenBalancesStorage = CommonTokenBalancesStorage(
        storage: storage(for: .cachedBalances)
    )

    lazy var yieldModuleStateRepository: YieldModuleStateRepository = CommonYieldModuleStateRepository(
        storage: storage(for: .cachedYieldModuleState)
    )

    lazy var yieldModuleMarketsRepository: YieldModuleMarketsRepository = CommonYieldModuleMarketsRepository(
        storage: storage(for: .cachedYieldMarkets)
    )

    init() {}

    func storage(for file: CachesDirectoryStorage.File) -> CachesDirectoryStorage {
        lock.lock()
        defer { lock.unlock() }

        let key = file.name
        if let existing = storages[key] {
            return existing
        }

        let storage = CachesDirectoryStorage(file: file)
        storages[key] = storage
        return storage
    }
}

// MARK: - Dependency Injection

private struct CachesProviderKey: InjectionKey {
    static var currentValue: CachesProviding = CachesProvider()
}

extension InjectedValues {
    var cachesProvider: CachesProviding {
        get { Self[CachesProviderKey.self] }
        set { Self[CachesProviderKey.self] = newValue }
    }
}
