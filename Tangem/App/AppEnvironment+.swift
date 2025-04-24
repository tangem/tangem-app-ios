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
        FeatureStorage.instance.useDevApi ?
            URL(string: "https://api.tests-d.com/v1")! :
            URL(string: "https://api.tangem.org/v1")!
    }

    var iconBaseUrl: URL {
        FeatureStorage.instance.useDevApi ?
            URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api.dev/")! :
            URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!
    }

    var tangemComBaseUrl: URL {
        if FeatureStorage.instance.useDevApi {
            return URL(string: "https://devweb.tangem.com")!
        } else {
            return URL(string: "https://tangem.com")!
        }
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
