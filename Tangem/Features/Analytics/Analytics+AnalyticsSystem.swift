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
    }
}

extension Array where Element == Analytics.AnalyticsSystem {
    static let all = Element.allCases
}
