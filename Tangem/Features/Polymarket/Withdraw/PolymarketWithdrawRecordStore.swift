//
//  PolymarketWithdrawRecordStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketWithdrawRecordStore {
    private let key: PersistentStorageKey
    private let storage: PersistentStorageProtocol

    init(
        userWalletId: UserWalletId,
        storage: PersistentStorageProtocol = InjectedValues[\.persistentStorage]
    ) {
        // The file name is visible regardless of file protection, so the wallet id goes into it only as an HMAC.
        key = .polymarketWithdrawRecord(cid: userWalletId.hashedStringValue(message: Constants.keyMessage))
        self.storage = storage
    }

    func entry() -> Entry? {
        do {
            return try storage.value(for: key)
        } catch {
            PolymarketLogger.error("The stored withdrawal could not be read", error: error)
            return nil
        }
    }

    func save(_ entry: Entry) {
        do {
            try storage.store(value: entry, for: key)
        } catch {
            PolymarketLogger.error("The withdrawal could not be stored", error: error)
        }
    }

    func delete() {
        do {
            try storage.remove(for: key)
        } catch {
            PolymarketLogger.error("The stored withdrawal could not be removed", error: error)
        }
    }
}

// MARK: - Entry

extension PolymarketWithdrawRecordStore {
    struct Entry: Equatable, Codable {
        let record: PolymarketWithdrawRecord
        let deadline: Date
        let settledAt: Date?

        func updated(with record: PolymarketWithdrawRecord, settledAt: Date?) -> Entry {
            Entry(record: record, deadline: deadline, settledAt: settledAt)
        }
    }
}

// MARK: - Constants

private extension PolymarketWithdrawRecordStore {
    enum Constants {
        static let keyMessage = "polymarket_withdraw_record"
    }
}
