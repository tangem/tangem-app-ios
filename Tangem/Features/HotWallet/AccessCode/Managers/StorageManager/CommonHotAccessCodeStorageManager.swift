//
//  CommonHotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonHotAccessCodeStorageManager {
    // [REDACTED_TODO_COMMENT]
    @AppStorageCompat(HotAccessCodeStorageKey.wrongAccessCode)
    private var wrongAccessCodes: [String: [Date]] = [:]

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
                manager.handleUserWalletRepositoryEvent(event: event)
            }
            .store(in: &bag)
    }

    func handleUserWalletRepositoryEvent(event: UserWalletRepositoryEvent) {
        switch event {
        case .unlockedBiometrics:
            userWalletRepository.models
                .filter { !$0.isUserWalletLocked }
                .map(\.userWalletId)
                .forEach {
                    clearWrongAccessCode(userWalletId: $0)
                }
        case .unlocked(let userWalletId):
            clearWrongAccessCode(userWalletId: userWalletId)
        default:
            break
        }
    }

    func wrongAccessCodesDates(userWalletId: UserWalletId) -> [Date] {
        wrongAccessCodes[userWalletId.stringValue] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> HotWrongAccessCodeStore {
        let dates = wrongAccessCodesDates(userWalletId: userWalletId)
        return HotWrongAccessCodeStore(dates: dates)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, date: Date) {
        var dates = wrongAccessCodesDates(userWalletId: userWalletId)
        dates.append(date)
        wrongAccessCodes[userWalletId.stringValue] = dates
    }

    func clearWrongAccessCode(userWalletId: UserWalletId) {
        wrongAccessCodes.removeValue(forKey: userWalletId.stringValue)
    }
}

// MARK: - StorageKey

private extension CommonHotAccessCodeStorageManager {
    enum HotAccessCodeStorageKey: String {
        /// Store wrong access code input events.
        case wrongAccessCode
    }
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
