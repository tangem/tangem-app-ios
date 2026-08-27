//
//  MobileBackupStorageUnavailableViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupStorageUnavailableViewModel: ObservableObject {
    let title = Localization.hwCloudBackupPermissionsTitleV2(MobileBackupConstants.iCloudServiceName)
    let description = Localization.hwCloudBackupPermissionsDescriptionV2(MobileBackupConstants.appleICloudServiceName)
    let actionTitle = Localization.commonGotIt

    private weak var coordinator: MobileBackupStorageUnavailableRoutable?

    init(coordinator: MobileBackupStorageUnavailableRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileBackupStorageUnavailableViewModel {
    func onCloseTap() {
        close()
    }

    func onActionTap() {
        close()
    }
}

// MARK: - Navigation

extension MobileBackupStorageUnavailableViewModel {
    func close() {
        runTask { [coordinator] in
            await coordinator?.dismissMobileBackupStorageUnavailable()
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupStorageUnavailableViewModel: FloatingSheetContentViewModel {}
