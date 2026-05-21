//
//  CommonOnrampUnknownStatusRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

final class CommonOnrampUnknownStatusRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let state = OSAllocatedUnfairLock<[OnrampUnknownStatusRecord]>(initialState: [])
    private let attempts = OSAllocatedUnfairLock<[String: Date]>(initialState: [:])
    private let saveQueue = DispatchQueue(label: "com.tangem.CommonOnrampUnknownStatusRepository.save")

    init() {
        loadRecords()
    }

    private func loadRecords() {
        do {
            let loaded: [OnrampUnknownStatusRecord] = try storage.value(for: .onrampUnknownStatuses) ?? []
            state.withLock { $0 = loaded }
        } catch {
            ExpressLogger.error("Couldn't load onramp unknown-status records from storage", error: error)
        }
    }

    private func saveAsync(_ records: [OnrampUnknownStatusRecord]) {
        saveQueue.async { [weak self] in
            guard let self else { return }
            do {
                try storage.store(value: records, for: .onrampUnknownStatuses)
            } catch {
                ExpressLogger.error("Couldn't save onramp unknown-status records to storage", error: error)
            }
        }
    }

    private func dropExpiredLocked(now: Date, in records: inout [OnrampUnknownStatusRecord]) -> [String] {
        var expired: [String] = []
        records.removeAll { record in
            guard record.expiresAt <= now else { return false }
            expired.append(record.id)
            return true
        }
        return expired
    }
}

extension CommonOnrampUnknownStatusRepository: OnrampUnknownStatusRepository {
    func markUnknown(_ record: OnrampUnknownStatusRecord) {
        let now = Date()
        let (snapshot, droppedIds): ([OnrampUnknownStatusRecord], [String]) = state.withLock { records in
            var dropped: [String] = []
            records.removeAll { existing in
                let shouldDrop = existing.expiresAt <= now || existing.id == record.id
                if shouldDrop { dropped.append(existing.id) }
                return shouldDrop
            }
            records.append(record)
            return (records, dropped)
        }
        attempts.withLock { dict in
            for id in droppedIds {
                dict.removeValue(forKey: id)
            }
            dict.removeValue(forKey: record.id)
        }
        saveAsync(snapshot)
    }

    func activeRecords(
        userWalletId: String,
        toContractAddress: String,
        toNetwork: String
    ) -> [OnrampUnknownStatusRecord] {
        let now = Date()
        let (records, expiredIds): ([OnrampUnknownStatusRecord], [String]) = state.withLock { records in
            let expired = dropExpiredLocked(now: now, in: &records)
            return (records, expired)
        }
        if !expiredIds.isEmpty {
            saveAsync(records)
        }
        let throttleCutoff = now.addingTimeInterval(-OnrampUnknownStatusRepositoryConstants.recoveryThrottle)
        let attemptsSnapshot: [String: Date] = attempts.withLock { dict in
            for id in expiredIds {
                dict.removeValue(forKey: id)
            }
            return dict
        }
        return records.filter { record in
            guard record.userWalletId == userWalletId,
                  record.toContractAddress.caseInsensitiveCompare(toContractAddress) == .orderedSame,
                  record.toNetwork.caseInsensitiveCompare(toNetwork) == .orderedSame
            else {
                return false
            }
            guard let lastAttempt = attemptsSnapshot[record.id] else {
                return true
            }
            return lastAttempt < throttleCutoff
        }
    }

    func markAttempted(recordId: String) {
        attempts.withLock { $0[recordId] = Date() }
    }

    func clear(recordId: String) {
        let snapshot: [OnrampUnknownStatusRecord]? = state.withLock { records in
            let original = records.count
            records.removeAll { $0.id == recordId }
            guard records.count != original else { return nil }
            return records
        }
        guard let snapshot else { return }
        attempts.withLock { $0.removeValue(forKey: recordId) }
        saveAsync(snapshot)
    }
}
