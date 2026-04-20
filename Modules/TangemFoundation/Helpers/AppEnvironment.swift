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
    case `internal` = "Internal"
}

public extension AppEnvironment {
    static var current: AppEnvironment {
        guard let environmentName: String = InfoDictionaryUtils.environmentName.value() else {
            // There is no info.plist SPM modules, so when running unit tests in SPM modules ENVIRONMENT_NAME can't be fetched
            if !isUnitTestInSPMModules {
                assertionFailure("ENVIRONMENT_NAME not found")
            }

            return .production
        }

        guard let environment = AppEnvironment(rawValue: environmentName) else {
            // There is no info.plist SPM modules, so when running unit tests in SPM modules ENVIRONMENT_NAME can't be fetched
            if !isUnitTestInSPMModules {
                assertionFailure("ENVIRONMENT_NAME not correct")
            }

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
        // Maestro passes launch arguments via UserDefaults, not ProcessInfo environment
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
            || UserDefaults.standard.string(forKey: "UITEST") == "1"
        #else
        return false
        #endif
    }

    var isInternalOrDebug: Bool {
        isDebug || !isProduction
    }

    var isProduction: Bool {
        self == .production
    }
}

// MARK: - Private implementation

private extension AppEnvironment {
    static var isUnitTestInSPMModules: Bool {
        ProcessInfo.processInfo.environment["XCODE_TEST_PLAN_NAME"]?.hasPrefix("TangemModules") == true
    }
}
