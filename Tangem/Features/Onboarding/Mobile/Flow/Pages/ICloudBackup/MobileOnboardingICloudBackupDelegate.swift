//
//  MobileOnboardingICloudBackupDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileOnboardingICloudBackupDelegate: AnyObject {
    func onICloudBackupComplete(savedCredential: WebCredentialUtil.SavedCredential?)
    func onICloudUnavailable()
    func onICloudBackupClose()
}
