//
//  TangemSdkConfigFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TangemSdkConfigFactory {
    func makeDefaultConfig() -> Config {
        var config = Config()
        config.filter.allowedCardTypes = [.release, .sdk]
        config.logConfig = AppLog.shared.sdkLogConfig
        config.filter.batchIdFilter = .deny([
            "0027", // [REDACTED_TODO_COMMENT]
            "0030",
            "0031",
            "0035",
        ])

        config.filter.issuerFilter = .deny(["TTM BANK"])
        if !FeatureProvider.isAvailable(.disableFirmwareVersionLimit) {
            config.filter.maxFirmwareVersion = FirmwareVersion(major: 6, minor: 33)
        }
        config.allowUntrustedCards = true
        config.biometricsLocalizedReason = Localization.biometryTouchIdReason
        config.style.colors.tint = Colors.Text.accent
        config.style.colors.buttonColors.backgroundColor = Colors.Button.positive

        return config
    }
}
