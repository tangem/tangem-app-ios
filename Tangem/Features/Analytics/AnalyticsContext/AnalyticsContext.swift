//
//  AnalyticsContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsContext {
    var contextData: AnalyticsContextData? { get }

    func setupContext(with: AnalyticsContextData)

    func clearContext()
    func clearSession()

    func value(forKey: AnalyticsStorageKey, scope: AnalyticsContextScope) -> Any?
    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope)
    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope)
}

// MARK: - Dependencies

private struct AnalyticsContextKey: InjectionKey {
    static var currentValue: AnalyticsContext = CommonAnalyticsContext()
}

extension InjectedValues {
    var analyticsContext: AnalyticsContext {
        get { Self[AnalyticsContextKey.self] }
        set { Self[AnalyticsContextKey.self] = newValue }
    }
}
