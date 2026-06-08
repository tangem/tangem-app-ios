//
//  SilentPushHandlersStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Owns and retains the silent-push subscribers for the app's lifetime.
///
/// Each handler self-subscribes to the silent-push bus in its own initializer, so the storage's
/// only job is to keep them alive (a deallocated handler would silently drop its subscription).
/// Registration is centralized in `initialize()` — add new silent-push handlers there.
protocol SilentPushHandlersStorage {
    func initialize()
}

final class CommonSilentPushHandlersStorage {
    private var handlers: [any SilentPushNotificationHandling] = []
}

// MARK: - SilentPushHandlersStorage

extension CommonSilentPushHandlersStorage: SilentPushHandlersStorage {
    func initialize() {
        // Register silent-push handlers here. Each one self-subscribes to the bus; the storage
        // just retains it so the subscription stays alive for the app's lifetime.
        handlers = [
            TransactionPushPortfolioUpdater(),
        ]
    }
}

// MARK: - Dependency injection

private struct SilentPushHandlersStorageKey: InjectionKey {
    static var currentValue: SilentPushHandlersStorage = CommonSilentPushHandlersStorage()
}

extension InjectedValues {
    var silentPushHandlersStorage: SilentPushHandlersStorage {
        get { Self[SilentPushHandlersStorageKey.self] }
        set { Self[SilentPushHandlersStorageKey.self] = newValue }
    }
}
