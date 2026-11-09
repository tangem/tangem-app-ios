//
//  ForceUpdateAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol ForceUpdateAnalyticsLogger {
    func logScreenShown(reason: ForceUpdateReason)
    func logUpdateNowTapped()
    func logContactSupportTapped(source: ForceUpdateSupportSource)
    func logLaterTapped()
}

enum ForceUpdateSupportSource {
    case criticalUpdate
    case unsupportedDevice

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .criticalUpdate: .critUpdate
        case .unsupportedDevice: .unsupportedDevice
        }
    }
}
