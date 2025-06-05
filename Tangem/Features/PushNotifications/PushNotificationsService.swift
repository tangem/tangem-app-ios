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
    func requestAuthorizationAndRegister() async
    func registerIfPossible() async
}

protocol PushNotificationEventsPublishing {
    var eventsPublisher: AnyPublisher<PushNotificationsEvent, Never> { get }
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
