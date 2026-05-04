//
//  WalletTokenAutoSyncProgressService.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

// MARK: - WalletTokenAutoSyncProgressService

protocol WalletTokenAutoSyncProgressService {
    func add(userWalletId: UserWalletId) async
    func remove(userWalletId: UserWalletId) async
    func reportProgress(userWalletId: UserWalletId, percent: Int) async
}

// MARK: - CommonWalletTokenAutoSyncProgressService

final class CommonWalletTokenAutoSyncProgressService: WalletTokenAutoSyncProgressService, WalletTokenAutoSyncProgressProvider {
    private let store = WalletTokenAutoSyncProgressStoreActor()

    func add(userWalletId: UserWalletId) async {
        await store.add(userWalletId: userWalletId)
    }

    func remove(userWalletId: UserWalletId) async {
        await store.remove(userWalletId: userWalletId)
    }

    func reportProgress(userWalletId: UserWalletId, percent: Int) async {
        await store.reportProgress(userWalletId: userWalletId, percent: percent)
    }

    func progressPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<Int, Never>? {
        await store.eventPublisher(for: userWalletId)
            .compactMap { event -> Int? in
                switch event {
                case .inProgress(let percent): return percent
                case .completed: return 100
                case .failed: return nil
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func eventPublisher(for userWalletId: UserWalletId) async -> AnyPublisher<WalletTokenAutoSyncProgressEvent, Never> {
        await store.eventPublisher(for: userWalletId)
    }

    func removeProgress(for userWalletId: UserWalletId) async {
        await store.remove(userWalletId: userWalletId)
    }

    // MARK: - Init

    nonisolated init() {}
}

// MARK: - WalletTokenAutoSyncProgressStoreActor

private actor WalletTokenAutoSyncProgressStoreActor {
    let eventSubject = CurrentValueSubject<[UserWalletId: WalletTokenAutoSyncProgressEvent], Never>([:])

    func add(userWalletId: UserWalletId) {
        eventSubject.value[userWalletId] = .inProgress(percent: 0)
    }

    func remove(userWalletId: UserWalletId) {
        eventSubject.value[userWalletId] = nil
    }

    func reportProgress(userWalletId: UserWalletId, percent: Int) {
        guard eventSubject.value[userWalletId] != nil else {
            return
        }

        AppLogger.tag("WalletTokenAutoSyncProgress").info("\(percent)%")

        if percent >= 100 {
            eventSubject.value[userWalletId] = .completed
        } else {
            eventSubject.value[userWalletId] = .inProgress(percent: percent)
        }
    }

    func eventPublisher(for userWalletId: UserWalletId) -> AnyPublisher<WalletTokenAutoSyncProgressEvent, Never> {
        eventSubject
            .compactMap { $0[userWalletId] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
