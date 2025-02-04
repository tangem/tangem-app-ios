//
//  Analytics+CardVerificationErrorSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension Analytics {
    enum CardVerificationErrorSource {
        case signIn
        case backup
        case onboarding
        case settings

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .backup:
                return .backup
            case .signIn:
                return .signIn
            case .onboarding:
                return .onboarding
            case .settings:
                return .settings
            }
        }
    }
}
