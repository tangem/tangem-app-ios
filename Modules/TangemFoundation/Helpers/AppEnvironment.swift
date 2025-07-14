//
//  AppEnvironment.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum AppEnvironment: String {
    case beta = "Beta"
    case production = "Production"
    case alpha = "Alpha"
}

public extension AppEnvironment {
    static var current: AppEnvironment {
        guard let environmentName: String = InfoDictionaryUtils.environmentName.value() else {
            assertionFailure("ENVIRONMENT_NAME not found")
            return .production
        }

        guard let environment = AppEnvironment(rawValue: environmentName) else {
            assertionFailure("ENVIRONMENT_NAME not correct")
            return .production
        }

        return environment
    }

    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var isUITest: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
        #else
        return false
        #endif
    }

    var isAlphaOrBetaOrDebug: Bool {
        isDebug || !isProduction
    }

    var isProduction: Bool {
        self == .production
    }
}
