//
//  TangemPayRecentOperationsStore.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TangemPayRecentOperationsStore {
    private let persistentStorage: PersistentStorageProtocol
    private let operations = OSAllocatedUnfairLock<[String: [TangemPayRecentOperation]]>(initialState: [:])
    private let operationsSubject = CurrentValueSubject<[String: [TangemPayRecentOperation]], Never>([:])

    init(persistentStorage: PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
    }

    func operationsPublisher(customerWalletId: String) -> AnyPublisher<[TangemPayRecentOperation], Never> {
        loadIfNeeded(customerWalletId: customerWalletId)

        return operationsSubject
            .map { $0[customerWalletId] ?? [] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func record(_ operation: TangemPayRecentOperation, customerWalletId: String) {
        loadIfNeeded(customerWalletId: customerWalletId)

        let updated = operations.withLock { operations in
            var walletOperations = operations[customerWalletId] ?? []
            walletOperations.removeAll { $0.repeatKey == operation.repeatKey }
            walletOperations.insert(operation, at: 0)
            walletOperations = Array(walletOperations.prefix(Constants.maxOperations))

            operations[customerWalletId] = walletOperations
            return operations
        }

        persist(updated[customerWalletId] ?? [], customerWalletId: customerWalletId)
        operationsSubject.send(updated)
    }

    func clear(customerWalletId: String) {
        let updated = operations.withLock { operations in
            operations[customerWalletId] = []
            return operations
        }

        do {
            try persistentStorage.remove(for: .tangemPayRecentOperations(cid: customerWalletId))
        } catch {
            AppLogger.error(error: error)
        }

        operationsSubject.send(updated)
    }
}

// MARK: - Private

private extension TangemPayRecentOperationsStore {
    func loadIfNeeded(customerWalletId: String) {
        let updated = operations.withLock { operations -> [String: [TangemPayRecentOperation]]? in
            guard operations[customerWalletId] == nil else {
                return nil
            }

            do {
                let stored: [TangemPayRecentOperation]? = try persistentStorage.value(
                    for: .tangemPayRecentOperations(cid: customerWalletId)
                )
                operations[customerWalletId] = stored ?? []
                return operations
            } catch {
                AppLogger.error(error: error)
                return nil
            }
        }

        if let updated {
            operationsSubject.send(updated)
        }
    }

    func persist(_ walletOperations: [TangemPayRecentOperation], customerWalletId: String) {
        do {
            try persistentStorage.store(value: walletOperations, for: .tangemPayRecentOperations(cid: customerWalletId))
        } catch {
            AppLogger.error(error: error)
        }
    }
}

// MARK: - Constants

private extension TangemPayRecentOperationsStore {
    enum Constants {
        static let maxOperations = 10
    }
}

// MARK: - Dependency injection

private struct TangemPayRecentOperationsStoreKey: InjectionKey {
    static var currentValue = TangemPayRecentOperationsStore(persistentStorage: InjectedValues[\.persistentStorage])
}

extension InjectedValues {
    var tangemPayRecentOperationsStore: TangemPayRecentOperationsStore {
        get { Self[TangemPayRecentOperationsStoreKey.self] }
        set { Self[TangemPayRecentOperationsStoreKey.self] = newValue }
    }
}
