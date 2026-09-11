//
//  MobileBackupICloudTypeDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

protocol MobileBackupICloudTypeDelegate: AnyObject {
    func onICloudBackupCreate() async
    func onICloudBackupDetails(backup: MobileWalletBackup, onDelete: @escaping () -> Void) async
    func onICloudBackupDeleted() async
    func onICloudBackupStorageUnavailable(output: MobileBackupStorageUnavailableOutput) async
    func onICloudBackupNotFound(output: MobileBackupNotFoundOutput) async
}
