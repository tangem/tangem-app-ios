//
//  MobileAccessCodeCleaner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MobileAccessCodeCleaner {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    private let manager: MobileAccessCodeStorageManager
    private var bag: Set<AnyCancellable> = []

    init(manager: MobileAccessCodeStorageManager) {
        self.manager = manager
    }
}

// MARK: - Private methods

private extension MobileAccessCodeCleaner {
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
                cleanSkippedAccessCode(userWalletId: $0)
            }

        default:
            break
        }
    }

    func cleanWrongAccessCode(userWalletId: UserWalletId) {
        manager.removeWrongAccessCode(userWalletId: userWalletId)
    }

    func cleanSkippedAccessCode(userWalletId: UserWalletId) {
        MobileAccessCodeSkipHelper.remove(userWalletId: userWalletId)
    }
}

// MARK: - Initializable

extension MobileAccessCodeCleaner: Initializable {
    func initialize() {
        bind()
    }
}
