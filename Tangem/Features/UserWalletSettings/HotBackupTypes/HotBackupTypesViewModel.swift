//
//  HotBackupTypesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotBackupTypesViewModel {
    let navTitle = Localization.commonBackup

    lazy var backupTypes = makeBackupTypes()

    private let userWalletModel: UserWalletModel
    private weak var routable: HotBackupTypesRoutable?

    init(userWalletModel: UserWalletModel, routable: HotBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.routable = routable
    }
}

// MARK: - Private methods

private extension HotBackupTypesViewModel {
    func makeBackupTypes() -> [BackupType] {
        [makeSeedBackupType(userWalletModel: userWalletModel), makeICloudBackupType()]
    }

    func makeSeedBackupType(userWalletModel: UserWalletModel) -> BackupType {
        let badge: BadgeView.Item
        let action: () -> Void

        // [REDACTED_TODO_COMMENT]
        if false {
            badge = .done
            action = { [weak routable] in
                routable?.openHotBackupRevealSeedPhrase(userWalletModel: userWalletModel)
            }
        } else {
            badge = .noBackup
            action = { [weak routable] in
                routable?.openHotBackupOnboardingSeedPhrase(userWalletModel: userWalletModel)
            }
        }

        return BackupType(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeICloudBackupType() -> BackupType {
        let badge = BadgeView.Item(title: Localization.commonComingSoon, style: .secondary)
        return BackupType(
            title: Localization.hwBackupIcloudTitle,
            description: Localization.hwBackupIcloudDescription,
            badge: badge,
            isEnabled: false,
            action: {}
        )
    }
}

// MARK: - Types

extension HotBackupTypesViewModel {
    struct BackupType: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let badge: BadgeView.Item
        let isEnabled: Bool
        let action: () -> Void
    }
}
