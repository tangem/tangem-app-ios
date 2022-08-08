//
//  Environment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

private let infoDictionary = Bundle.main.infoDictionary ?? [:]

enum AppEnvironment: String {
    case beta = "Beta"
    case production = "Production"
}

extension AppEnvironment {
    static var current: AppEnvironment {
        guard let environmentName = infoDictionary["ENVIRONMENT_NAME"] as? String else {
            assertionFailure("ENVIRONMENT_NAME not found")
            return .production
        }

        guard let environment = AppEnvironment(rawValue: environmentName) else {
            assertionFailure("ENVIRONMENT_NAME not correct")
            return .production
        }

        return environment
    }

    var suiteName: String {
        guard let identifier = infoDictionary["SUITE_NAME"] as? String else {
            assertionFailure("SUITE_NAME not found")
            return ""
        }

        return identifier
    }
}
