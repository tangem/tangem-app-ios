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

    private weak var routable: HotBackupTypesRoutable?

    init(routable: HotBackupTypesRoutable) {
        self.routable = routable
    }
}

// MARK: - Private methods

private extension HotBackupTypesViewModel {
    func makeBackupTypes() -> [BackupType] {
        [makeSeedBackupType(), makeICloudBackupType()]
    }

    func makeSeedBackupType() -> BackupType {
        let badge: BadgeView.Item
        let action: () -> Void

        // [REDACTED_TODO_COMMENT]
        if false {
            badge = BadgeView.Item(title: Localization.commonDone, style: .accent)
            action = { [routable] in
                routable?.openHotBackupSeedPhrase()
            }
        } else {
            badge = BadgeView.Item(title: Localization.hwBackupNoBackup, style: .warning)
            action = { [routable] in
                routable?.openHotBackupOnboarding()
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
