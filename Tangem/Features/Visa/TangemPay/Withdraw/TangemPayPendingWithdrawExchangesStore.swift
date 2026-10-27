//
//  TangemPayPendingWithdrawExchangesStore.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress
import TangemFoundation

struct TangemPayPendingWithdrawExchange: Codable {
    let orderId: String
    let createdAt: Date
    let tokenItem: TokenItem
    let fromAddress: String
    let transactionData: ExpressTransactionData
}

final class TangemPayPendingWithdrawExchangesStore {
    private let persistentStorage: PersistentStorageProtocol
    private let cachedExchanges = OSAllocatedUnfairLock<[UserWalletId: [TangemPayPendingWithdrawExchange]]>(initialState: [:])
    private let exchangesSubject = CurrentValueSubject<[UserWalletId: [TangemPayPendingWithdrawExchange]], Never>([:])

    init(persistentStorage: PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
    }

    func exchanges(userWalletId: UserWalletId) -> [TangemPayPendingWithdrawExchange] {
        loadIfNeeded(userWalletId: userWalletId)

        return cachedExchanges.withLock { $0[userWalletId] ?? [] }
    }

    func exchangesPublisher(userWalletId: UserWalletId) -> AnyPublisher<[TangemPayPendingWithdrawExchange], Never> {
        loadIfNeeded(userWalletId: userWalletId)

        return exchangesSubject
            .map { $0[userWalletId] ?? [] }
            .eraseToAnyPublisher()
    }

    func add(_ exchange: TangemPayPendingWithdrawExchange, userWalletId: UserWalletId) {
        update(userWalletId: userWalletId) { walletExchanges in
            walletExchanges.removeAll { $0.orderId == exchange.orderId }
            walletExchanges.append(exchange)
        }
    }

    func remove(orderId: String, userWalletId: UserWalletId) {
        update(userWalletId: userWalletId) { walletExchanges in
            walletExchanges.removeAll { $0.orderId == orderId }
        }
    }

    func clear(userWalletId: UserWalletId) {
        let updated = cachedExchanges.withLock { exchanges in
            exchanges[userWalletId] = []
            persist([], userWalletId: userWalletId)
            return exchanges
        }

        exchangesSubject.send(updated)
    }
}

// MARK: - Private

private extension TangemPayPendingWithdrawExchangesStore {
    func update(userWalletId: UserWalletId, _ transform: (inout [TangemPayPendingWithdrawExchange]) -> Void) {
        loadIfNeeded(userWalletId: userWalletId)

        let updated = cachedExchanges.withLock { exchanges in
            var walletExchanges = exchanges[userWalletId] ?? []
            transform(&walletExchanges)
            exchanges[userWalletId] = walletExchanges
            persist(walletExchanges, userWalletId: userWalletId)
            return exchanges
        }

        exchangesSubject.send(updated)
    }

    func loadIfNeeded(userWalletId: UserWalletId) {
        let updated = cachedExchanges.withLock { exchanges -> [UserWalletId: [TangemPayPendingWithdrawExchange]]? in
            guard exchanges[userWalletId] == nil else {
                return nil
            }

            do {
                let stored: [TangemPayPendingWithdrawExchange]? = try persistentStorage.value(
                    for: .tangemPayPendingWithdrawExchanges(userWalletId: userWalletId)
                )
                exchanges[userWalletId] = stored ?? []
                return exchanges
            } catch {
                AppLogger.error(error: error)
                return nil
            }
        }

        if let updated {
            exchangesSubject.send(updated)
        }
    }

    func persist(_ walletExchanges: [TangemPayPendingWithdrawExchange], userWalletId: UserWalletId) {
        do {
            if walletExchanges.isEmpty {
                try persistentStorage.remove(for: .tangemPayPendingWithdrawExchanges(userWalletId: userWalletId))
            } else {
                try persistentStorage.store(value: walletExchanges, for: .tangemPayPendingWithdrawExchanges(userWalletId: userWalletId))
            }
        } catch {
            AppLogger.error(error: error)
        }
    }
}

// MARK: - Dependency injection

private struct TangemPayPendingWithdrawExchangesStoreKey: InjectionKey {
    static var currentValue = TangemPayPendingWithdrawExchangesStore(persistentStorage: InjectedValues[\.persistentStorage])
}

extension InjectedValues {
    var tangemPayPendingWithdrawExchangesStore: TangemPayPendingWithdrawExchangesStore {
        get { Self[TangemPayPendingWithdrawExchangesStoreKey.self] }
        set { Self[TangemPayPendingWithdrawExchangesStoreKey.self] = newValue }
    }
}
