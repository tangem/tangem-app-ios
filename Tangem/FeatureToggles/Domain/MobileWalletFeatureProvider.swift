//
//  MobileWalletFeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct MobileWalletFeatureProvider {
    private let targetMajor = 18
    private let targetMinor = 0

    var isAvailable: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(targetVersion)
    }

    private var targetVersion: OperatingSystemVersion {
        OperatingSystemVersion(majorVersion: targetMajor, minorVersion: targetMinor, patchVersion: 0)
    }

    func makeRestrictionAlert() -> AlertBinder {
        let targetVersionString = "iOS \(targetMajor).\(targetMinor)"
        let title = Localization.mobileWalletRequiresMinOsWarningTitle(targetVersionString)
        let message = Localization.mobileWalletRequiresMinOsWarningBody(targetVersionString)
        return AlertBuilder.makeAlert(
            title: title,
            message: message,
            primaryButton: .default(Text(Localization.commonGotIt))
        )
    }
}
