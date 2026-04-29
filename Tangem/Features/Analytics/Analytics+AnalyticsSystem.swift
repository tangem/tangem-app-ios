//
//  Analytics+AnalyticsSystem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

extension Analytics {
    enum AnalyticsSystem: CaseIterable {
        case firebase
        case amplitude
        case crashlytics
        case appsFlyer

        var logBadge: String {
            switch self {
            case .firebase: return "FB"
            case .amplitude: return "AM"
            case .crashlytics: return "CL"
            case .appsFlyer: return "AF"
            }
        }
    }
}

extension Array where Element == Analytics.AnalyticsSystem {
    static let all = Element.allCases
    static let defaultSystems: [Analytics.AnalyticsSystem] = [.firebase, .amplitude, .crashlytics]
}
