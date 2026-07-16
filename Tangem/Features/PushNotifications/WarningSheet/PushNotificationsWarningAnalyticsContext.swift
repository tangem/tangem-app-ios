//
//  PushNotificationsWarningAnalyticsContext.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Shared context for the Warning Screen analytics events (`Shown` / `Enable Tapped` / `Skip Tapped`).
struct PushNotificationsWarningAnalyticsContext {
    let zone: Zone
    let variant: Variant
    /// Passed only in the Main zone (there is no wallet during onboarding).
    let walletId: String?

    var params: [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [
            .variant: variant.parameterValue.rawValue,
            .zone: zone.parameterValue.rawValue,
        ]

        if let walletId {
            params[.walletId] = walletId
        }

        return params
    }
}

// MARK: - Nested types

extension PushNotificationsWarningAnalyticsContext {
    enum Zone {
        case onboarding
        case main

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .onboarding: .zoneOnboarding
            case .main: .zoneMain
            }
        }
    }

    enum Variant {
        case control
        case treatment

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .control: .control
            case .treatment: .treatment
            }
        }
    }
}
