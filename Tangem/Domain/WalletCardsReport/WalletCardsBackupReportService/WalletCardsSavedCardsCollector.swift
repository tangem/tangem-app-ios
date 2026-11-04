//
//  WalletCardsSavedCardsCollector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

struct WalletCardsSavedCardsCollector {
    private let userWalletRepository: UserWalletRepository

    init(userWalletRepository: UserWalletRepository) {
        self.userWalletRepository = userWalletRepository
    }

    var incompleteBackupCardsPublisher: AnyPublisher<[WalletCardsCurrentlyProcessedCard], Never> {
        userWalletRepository.eventProvider
            .filter { event in
                switch event {
                case .unlocked, .unlockedWallet: true
                default: false
                }
            }
            .prepend(.unlocked)
            .receiveOnMain()
            .map { _ in incompleteBackupCards() }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension WalletCardsSavedCardsCollector {
    func incompleteBackupCards() -> [WalletCardsCurrentlyProcessedCard] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .compactMap(incompleteBackupCard(of:))
    }

    func incompleteBackupCard(of model: UserWalletModel) -> WalletCardsCurrentlyProcessedCard? {
        guard !model.config.isDemo,
              !model.backupState.isValid,
              let card = (model.config as? WalletOnboardingStepsBuilderFactory)?.card,
              card.settings.isBackupAllowed,
              let backupStatus = card.backupStatus.map(WalletCardsBackupCard.BackupStatus.init),
              backupStatus != .noBackup else {
            return nil
        }

        return WalletCardsCurrentlyProcessedCard(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            role: nil,
            identity: .filled(userWalletId: model.userWalletId.stringValue, isImported: model.hasImportedWallets),
            curves: card.walletCurves,
            backupStatus: backupStatus
        )
    }
}
