//
//  CommonPushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import TangemFoundation
import Combine

final class CommonPushNotificationsService: NSObject {
    private let requestedAuthorizationOptions: UNAuthorizationOptions = [
        .alert,
        .badge,
        .sound,
    ]

    private let validAuthorizationStatuses: Set<UNAuthorizationStatus> = [
        .authorized,
        .ephemeral,
    ]

    private let _didReceiveEvent = PassthroughSubject<PushNotificationsEvent, Never>()
    private var respondedNotificationIds: Set<String> = []
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let application: UIApplication
    private var bag = Set<AnyCancellable>()
    private var isForegroundPushDisplayEnabled = true

    init(application: UIApplication) {
        self.application = application
        super.init()
        userNotificationCenter.delegate = self
        bind()
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        application.registerForRemoteNotifications()
    }

    private func bind() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isForegroundPushDisplayEnabled = false
            }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isForegroundPushDisplayEnabled = true
            }
            .store(in: &bag)
    }
}

// MARK: - PushNotificationEventsPublishing

extension CommonPushNotificationsService: PushNotificationEventsPublishing {
    var eventsPublisher: AnyPublisher<PushNotificationsEvent, Never> {
        _didReceiveEvent.eraseToAnyPublisher()
    }
}

// MARK: - PushNotificationsPermissionService

extension CommonPushNotificationsService: PushNotificationsPermissionService {
    /// - Note: Checks only explicit authorization (`UNAuthorizationStatus.authorized`) and ignores implicit
    /// authorization statuses such as `UNAuthorizationStatus.provisional` or `UNAuthorizationStatus.ephemeral`.
    @MainActor
    var isAuthorized: Bool {
        get async {
            let notificationSettings = await userNotificationCenter.notificationSettings()
            return notificationSettings.authorizationStatus == .authorized
        }
    }

    func registerIfPossible() async {
        let notificationSettings = await userNotificationCenter.notificationSettings()
        if validAuthorizationStatuses.contains(notificationSettings.authorizationStatus) {
            await registerForRemoteNotifications()
        }
    }

    func requestAuthorizationAndRegister() async {
        do {
            let granted = try await userNotificationCenter.requestAuthorization(options: requestedAuthorizationOptions)

            if granted {
                _didReceiveEvent.send(.authorization(.granted))
                await registerForRemoteNotifications()
            } else {
                _didReceiveEvent.send(.authorization(.deniedOrUndetermined))
            }

        } catch {
            _didReceiveEvent.send(.authorization(.failed(error)))
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension CommonPushNotificationsService: UNUserNotificationCenterDelegate {
    /// Without `@MainActor` provoke crash on iOS 18.2
    /// With exception:
    /// *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Call must be made on main thread'
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier

        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              !respondedNotificationIds.contains(identifier)
        else {
            return
        }

        respondedNotificationIds.insert(identifier)
        _didReceiveEvent.send(.receivedResponse(response))
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(isForegroundPushDisplayEnabled ? .banner : [])
    }
}
