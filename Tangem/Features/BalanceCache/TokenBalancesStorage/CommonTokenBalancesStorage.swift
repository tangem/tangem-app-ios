//
//  CommonTokenBalancesStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class CommonTokenBalancesStorage {
    /**
     The balances are stored in this json structure
     ```
     {
        "userWalletId":{
            "wallet.id":{
                "available":{ "balance":0.1, "date":"date" },
                "staking":{ "balance":0.1, "date":"date" }
            }
        }
     }
     ```
     */
    private typealias Balances = [String: [String: [String: CachedBalance]]]

    private let storage: CachesDirectoryStorage
    private let balances: CurrentValueSubject<Balances, Never>
    private var bag: Set<AnyCancellable> = []

    init(storage: CachesDirectoryStorage) {
        self.storage = storage
        let cachedBalances: Balances? = try? storage.value()
        balances = .init(cachedBalances ?? [:])

        bind()
    }
}

// MARK: - TokenBalancesStorage

extension CommonTokenBalancesStorage: TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: UserWalletId) {
        var balancesForUserWallet = balances.value[userWalletId.stringValue, default: [:]]
        var balancesForWalletModel = balancesForUserWallet[id.id, default: [:]]
        balancesForWalletModel.updateValue(balance, forKey: type.rawValue)
        balancesForUserWallet.updateValue(balancesForWalletModel, forKey: id.id)
        balances.value.updateValue(balancesForUserWallet, forKey: userWalletId.stringValue)
    }

    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance? {
        balances.value[userWalletId.stringValue]?[id.id]?[type.rawValue]
    }
}

// MARK: - Private

private extension CommonTokenBalancesStorage {
    func bind() {
        balances
            .dropFirst()
            .removeDuplicates()
            // Add small debounce to reduce impact to write to disk operation
            .debounce(for: 0.1, scheduler: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .receiveValue { $0.save(balances: $1) }
            .store(in: &bag)
    }

    private func save(balances: Balances) {
        do {
            try storage.storeAndWait(value: balances)
        } catch {
            AppLogger.error("Storage save error", error: error)
        }
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenBalancesStorage: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "balancesCount": balances.value.flatMap(\.value).flatMap(\.value).count,
        ])
    }
}
