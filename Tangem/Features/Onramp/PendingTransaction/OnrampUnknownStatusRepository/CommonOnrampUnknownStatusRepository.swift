//
//  CommonOnrampUnknownStatusRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress

final class CommonOnrampUnknownStatusRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonOnrampUnknownStatusRepository.lockQueue")
    private let recordsSubject = CurrentValueSubject<[OnrampUnknownStatusRecord], Never>([])
    private var attempts: [String: Date] = [:]

    init() {
        loadRecords()
    }

    private func loadRecords() {
        do {
            recordsSubject.value = try storage.value(for: .onrampUnknownStatuses) ?? []
        } catch {
            ExpressLogger.error("Couldn't load onramp unknown-status records from storage", error: error)
        }
    }

    private func saveChanges() {
        do {
            try storage.store(value: recordsSubject.value, for: .onrampUnknownStatuses)
        } catch {
            ExpressLogger.error("Couldn't save onramp unknown-status records to storage", error: error)
        }
    }

    /// Must be called from `lockQueue`. Ordering between this and other queue work is preserved by the serial queue,
    /// so an async expiry can never overtake a later async `track` / `untrack`.
    private func pruneExpiredLocked(now: Date) -> [String] {
        var expired: [String] = []
        var records = recordsSubject.value
        records.removeAll { record in
            guard record.expiresAt <= now else { return false }
            expired.append(record.id)
            return true
        }
        if !expired.isEmpty {
            recordsSubject.value = records
            for id in expired {
                attempts.removeValue(forKey: id)
            }
        }
        return expired
    }
}

extension CommonOnrampUnknownStatusRepository: OnrampUnknownStatusRepository {
    var recordsPublisher: AnyPublisher<[OnrampUnknownStatusRecord], Never> {
        recordsSubject.eraseToAnyPublisher()
    }

    func track(_ record: OnrampUnknownStatusRecord) {
        lockQueue.sync {
            let now = Date()
            _ = pruneExpiredLocked(now: now)
            var records = recordsSubject.value
            records.removeAll { $0.id == record.id }
            records.append(record)
            attempts.removeValue(forKey: record.id)
            recordsSubject.value = records
            saveChanges()
        }
    }

    func pendingRecoveryCandidates(
        userWalletId: String,
        toContractAddress: String,
        toNetwork: String
    ) -> [OnrampUnknownStatusRecord] {
        let now = Date()
        let throttleCutoff = now.addingTimeInterval(-OnrampUnknownStatusRepositoryConstants.recoveryThrottle)
        let (snapshot, attemptsSnapshot): ([OnrampUnknownStatusRecord], [String: Date]) = lockQueue.sync {
            (recordsSubject.value, attempts)
        }
        lockQueue.async { [weak self] in
            guard let self else { return }
            if !pruneExpiredLocked(now: now).isEmpty {
                saveChanges()
            }
        }
        return snapshot.filter { record in
            guard record.expiresAt > now,
                  record.userWalletId == userWalletId,
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

    func noteRecoveryProbe(recordId: String) {
        lockQueue.sync {
            attempts[recordId] = Date()
        }
    }

    func untrack(recordId: String) {
        lockQueue.async { [weak self] in
            guard let self else { return }
            var records = recordsSubject.value
            let original = records.count
            records.removeAll { $0.id == recordId }
            guard records.count != original else { return }
            attempts.removeValue(forKey: recordId)
            recordsSubject.value = records
            saveChanges()
        }
    }
}
