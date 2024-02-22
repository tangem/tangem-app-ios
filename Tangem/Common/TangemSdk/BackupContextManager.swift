//
//  BackupContextManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BackupContextManager {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private weak var userWalletModel: UserWalletModel?

    private var associatedCardIds: Set<String> = []
    private var hasBackupErrors: Bool = false

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func onProceedBackup(_ card: Card) {
        guard let userWalletModel else {
            return
        }

        associatedCardIds.insert(card.cardId)

        let curvesValidator = CurvesValidator(expectedCurves: userWalletModel.config.mandatoryCurves)
        let backupValidator = BackupValidator()

        if !curvesValidator.validate(card.wallets.map { $0.curve }) || !backupValidator.validate(card.backupStatus) {
            hasBackupErrors = true
        }
    }

    func onCompleteBackup() {
        guard let userWalletModel else {
            return
        }

        var userWallet = userWalletModel.userWallet
        userWallet.associatedCardIds = associatedCardIds
        userWallet.hasBackupErrors = hasBackupErrors
        userWalletRepository.save(userWallet)
    }
}
