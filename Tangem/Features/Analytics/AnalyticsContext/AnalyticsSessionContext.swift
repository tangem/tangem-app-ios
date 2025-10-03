//
//  AnalyticsSessionContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsSessionContext {
    func value(forKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope) -> Any?
    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope)
    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope)
}

// MARK: - Dependencies

private struct AnalyticsContextKey: InjectionKey {
    static var currentValue: AnalyticsSessionContext = CommonAnalyticsSessionContext()
}

extension InjectedValues {
    var analyticsContext: AnalyticsSessionContext {
        get { Self[AnalyticsContextKey.self] }
        set { Self[AnalyticsContextKey.self] = newValue }
    }
}
