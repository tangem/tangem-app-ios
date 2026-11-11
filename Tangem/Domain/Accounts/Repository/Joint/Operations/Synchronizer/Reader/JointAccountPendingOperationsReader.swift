//
//  JointAccountPendingOperationsReader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class JointAccountPendingOperationsReader {
    private let persistentStorage: JointAccountsPendingOperationsPersistentStorage
    private let safeAddressResolver: JointAccountSafeAddressResolver
    private let cache = OSAllocatedUnfairLock<[JointAccountOperations]>(initialState: [])
    private let reloadQueue = DispatchQueue(label: "com.tangem.JointAccountPendingOperationsReader.reloadQueue", qos: .userInitiated)

    var pendingOperations: [JointAccountOperations] {
        cache.withLock { $0 }
    }

    init(persistentStorage: JointAccountsPendingOperationsPersistentStorage, safeAddressResolver: JointAccountSafeAddressResolver) {
        self.persistentStorage = persistentStorage
        self.safeAddressResolver = safeAddressResolver
    }

    @discardableResult
    func reload() -> [JointAccountOperations] {
        reloadQueue.sync {
            let records = readInFlightOperations()
            cache.withLock { $0 = records }

            return records
        }
    }

    func operation(id: String) -> JointAccountOperation? {
        do {
            return try persistentStorage.operation(id: id)?.operation
        } catch {
            JointAccountsLogger.error("Unable to read a stored joint operation", error: error)
            return nil
        }
    }

    private func readInFlightOperations() -> [JointAccountOperations] {
        let directory = JointAccountSafeDirectory(safeAddressResolver.accountSafes)

        do {
            let items = try persistentStorage.inFlightOperations(safeAddresses: directory.safeAddresses)
            return directory.records(from: items)
        } catch {
            JointAccountsLogger.error("Unable to read the pending joint account operations of a wallet", error: error)
            return []
        }
    }
}
