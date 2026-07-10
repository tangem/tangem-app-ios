//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

typealias PushNotificationsService = PushNotificationsPermissionService & PushNotificationEventsPublishing

protocol PushNotificationsPermissionService {
    @MainActor var isAuthorized: Bool { get async }

    /// Emits the current authorization status each time the app becomes active.
    var isAuthorizedPublisher: AnyPublisher<Bool, Never> { get }

    func requestAuthorizationAndRegister() async
    func registerIfPossible() async
}

protocol PushNotificationEventsPublishing {
    var eventsPublisher: AnyPublisher<PushNotificationsEvent, Never> { get }
}

extension PushNotificationsPermissionService {
    /// Whether push notifications are authorized, requesting the system prompt first when authorization
    /// hasn't been determined yet (a no-op when already denied). Callers fall back to their own
    /// "open Settings" affordance if this still returns `false`.
    func ensureAuthorized() async -> Bool {
        if await isAuthorized {
            return true
        }

        await requestAuthorizationAndRegister()
        return await isAuthorized
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var pushNotificationsPermission: PushNotificationsPermissionService {
        service
    }

    var pushNotificationsEventsPublisher: PushNotificationEventsPublishing {
        service
    }

    private var service: PushNotificationsService {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: PushNotificationsService = CommonPushNotificationsService(application: .shared)
    }
}
