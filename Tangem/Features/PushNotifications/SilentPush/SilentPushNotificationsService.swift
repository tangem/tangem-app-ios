//
//  SilentPushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Raw payload of a silent (content-available) remote notification.
///
/// Wraps `[AnyHashable: Any]` so it can travel through Combine without tripping `Sendable` checks.
/// Each handler decides how to interpret `raw` (e.g. parse it as a `TransactionPushPayload`).
struct SilentPushUserInfo: @unchecked Sendable {
    let raw: [AnyHashable: Any]
}

/// A single, self-contained consumer of silent push payloads. Conformers subscribe to
/// `SilentPushNotificationsPublishing` themselves and pick out only the payloads they care about.
protocol SilentPushNotificationHandling: AnyObject {
    func handle(_ userInfo: SilentPushUserInfo)
}

/// Producer side: where the app feeds incoming silent push payloads (called from `AppDelegate`).
protocol SilentPushNotificationsReceiving {
    func receive(_ userInfo: SilentPushUserInfo)
}

/// Consumer side: a fan-out stream that any number of `SilentPushNotificationHandling` subscribers observe.
protocol SilentPushNotificationsPublishing {
    var silentPushPublisher: AnyPublisher<SilentPushUserInfo, Never> { get }
}

typealias SilentPushNotificationsService = SilentPushNotificationsReceiving & SilentPushNotificationsPublishing

/// Decouples the silent-push entry point (`AppDelegate`) from the handlers that act on payloads.
/// A thin transport: it only relays payloads onto a subject — all interpretation lives in subscribers.
final class CommonSilentPushNotificationsService {
    private let subject = PassthroughSubject<SilentPushUserInfo, Never>()
}

// MARK: - SilentPushNotificationsReceiving

extension CommonSilentPushNotificationsService: SilentPushNotificationsReceiving {
    func receive(_ userInfo: SilentPushUserInfo) {
        subject.send(userInfo)
    }
}

// MARK: - SilentPushNotificationsPublishing

extension CommonSilentPushNotificationsService: SilentPushNotificationsPublishing {
    var silentPushPublisher: AnyPublisher<SilentPushUserInfo, Never> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var silentPushNotificationsReceiver: SilentPushNotificationsReceiving {
        service
    }

    var silentPushNotificationsPublisher: SilentPushNotificationsPublishing {
        service
    }

    private var service: SilentPushNotificationsService {
        get { Self[SilentPushNotificationsServiceKey.self] }
        set { Self[SilentPushNotificationsServiceKey.self] = newValue }
    }

    private struct SilentPushNotificationsServiceKey: InjectionKey {
        static var currentValue: SilentPushNotificationsService = CommonSilentPushNotificationsService()
    }
}
