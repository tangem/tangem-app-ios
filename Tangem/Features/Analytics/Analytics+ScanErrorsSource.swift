//
//  Analytics+ScanErrorsSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension Analytics {
    enum ScanErrorsSource {
        case signIn
        case backup
        case onboarding
        case settings
        case main
        case deviceSettings
        case introduction
        case sign
        case upgrade

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
            case .introduction:
                return .introduction
            case .main:
                return .main
            case .deviceSettings:
                return .deviceSettings
            case .sign:
                return .sign
            case .upgrade:
                return .upgrade
            }
        }
    }
}
