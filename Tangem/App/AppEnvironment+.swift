//
//  AppEnvironment+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension AppEnvironment {
    var suiteName: String {
        guard let identifier: String = InfoDictionaryUtils.suiteName.value() else {
            assertionFailure("SUITE_NAME not found")
            return ""
        }

        return identifier
    }

    var blockchainDataStorageSuiteName: String {
        guard let identifier: String = InfoDictionaryUtils.bsdkSuiteName.value() else {
            assertionFailure("BSDK_SUITE_NAME not found")
            return ""
        }

        return identifier
    }

    var apiBaseUrl: URL {
        FeatureStorage.instance.tangemAPIType.apiBaseUrl
    }

    var apiBaseUrlv2: URL {
        FeatureStorage.instance.tangemAPIType.apiBaseUrlv2
    }

    var iconBaseUrl: URL {
        FeatureStorage.instance.tangemAPIType.iconBaseUrl
    }

    var tangemComBaseUrl: URL {
        FeatureStorage.instance.tangemAPIType.tangemComBaseUrl
    }

    var activatePromoCodeBaseUrl: URL {
        FeatureStorage.instance.tangemAPIType.activatePromoCodeApiBaseUrl
    }

    var isTestnet: Bool {
        FeatureStorage.instance.isTestnet
    }

    var isXcodePreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var configFileName: String {
        if isDebug {
            return "config_dev"
        }

        switch self {
        case .production:
            return "config_prod"
        case .beta:
            return "config_beta"
        case .alpha:
            return "config_alpha"
        }
    }
}
