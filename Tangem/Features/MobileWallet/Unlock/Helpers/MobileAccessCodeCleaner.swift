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
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let commonStorageManager: MobileAccessCodeStorageManager = CommonMobileAccessCodeStorageManager()

    private var bag: Set<AnyCancellable> = []
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
        case .unlocked:
            userWalletRepository.models
                .filter { !$0.isUserWalletLocked }
                .map(\.userWalletId)
                .forEach {
                    cleanWrongAccessCode(userWalletId: $0)
                }

        case .unlockedWallet(let userWalletId):
            cleanWrongAccessCode(userWalletId: userWalletId)

        case .deleted(let userWalletIds, _):
            userWalletIds.forEach {
                cleanWrongAccessCode(userWalletId: $0)
            }

        default:
            break
        }
    }

    func cleanWrongAccessCode(userWalletId: UserWalletId) {
        commonStorageManager.removeWrongAccessCode(userWalletId: userWalletId)
    }
}

// MARK: - Initializable

extension MobileAccessCodeCleaner: Initializable {
    func initialize() {
        bind()
    }
}
