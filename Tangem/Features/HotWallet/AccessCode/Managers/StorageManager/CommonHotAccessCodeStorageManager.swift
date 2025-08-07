//
//  CommonHotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonHotAccessCodeStorageManager {
    @AppStorageCompat(HotAccessCodeStorageKey.wrongAccessCode)
    private var userWalletIdsWithWrongAccessCodes: [String: [TimeInterval]] = [:]

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private var bag: Set<AnyCancellable> = []

    fileprivate init() {}
}

// MARK: - Private methods

private extension CommonHotAccessCodeStorageManager {
    func bind() {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { manager, event in
                manager.handleUserWalletRepositoryEvent(event)
            }
            .store(in: &bag)
    }

    func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .unlockedBiometrics:
            userWalletRepository.models
                .filter { !$0.isUserWalletLocked }
                .map(\.userWalletId)
                .forEach {
                    cleanWrongAccessCode(userWalletId: $0)
                }

        case .unlocked(let userWalletId):
            cleanWrongAccessCode(userWalletId: userWalletId)

        case .deleted(let userWalletIds):
            userWalletIds.forEach {
                cleanWrongAccessCode(userWalletId: $0)
            }

        default:
            break
        }
    }

    func wrongAccessCodesLockIntervals(userWalletId: UserWalletId) -> [TimeInterval] {
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> HotWrongAccessCodeStore {
        let lockIntervals = wrongAccessCodesLockIntervals(userWalletId: userWalletId)
        return HotWrongAccessCodeStore(lockIntervals: lockIntervals)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, lockInterval: TimeInterval) {
        var lockIntervals = wrongAccessCodesLockIntervals(userWalletId: userWalletId)
        lockIntervals.append(lockInterval)
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] = lockIntervals
    }

    func cleanWrongAccessCode(userWalletId: UserWalletId) {
        userWalletIdsWithWrongAccessCodes.removeValue(forKey: userWalletId.stringValue)
    }
}

// MARK: - StorageKey

private enum HotAccessCodeStorageKey: String {
    /// Store wrong access code input events.
    case wrongAccessCode
}

// MARK: - Initializable

extension CommonHotAccessCodeStorageManager: Initializable {
    func initialize() {
        bind()
    }
}

// MARK: - Injections

extension InjectedValues {
    var hotAccessCodeStorageManager: HotAccessCodeStorageManager {
        get { Self[HotAccessCodeStorageManagerKey.self] }
        set { Self[HotAccessCodeStorageManagerKey.self] = newValue }
    }
}

private struct HotAccessCodeStorageManagerKey: InjectionKey {
    static var currentValue: HotAccessCodeStorageManager = CommonHotAccessCodeStorageManager()
}
