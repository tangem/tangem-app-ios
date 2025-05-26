//
//  CommonNotificationResponseDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

final class CommonNotificationResponseDispatcher: NSObject {
    private var respondedNotificationIds: Set<String> = []
    private lazy var subscribers = [any PushNotificationSubscriber]()
    private let userNotificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        userNotificationCenter.delegate = self
    }

    @MainActor
    private func notifyListeners(of response: UNNotificationResponse) {
        subscribers.forEach { $0.handleResponse(response) }
    }
}

// MARK: - NotificationResponseDispatching

extension CommonNotificationResponseDispatcher: NotificationResponseDispatching {
    func register(subscriber: any PushNotificationSubscriber) {
        subscribers.append(subscriber)
    }

    func unregister(subscriber: any PushNotificationSubscriber) {
        if let index = subscribers.firstIndex(where: { $0 === subscriber }) {
            subscribers.remove(at: index)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension CommonNotificationResponseDispatcher: UNUserNotificationCenterDelegate {
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier
        notifyListeners(of: response)

        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              !respondedNotificationIds.contains(identifier)
        else {
            return
        }

        respondedNotificationIds.insert(identifier)
        Analytics.log(.pushNotificationOpened)
    }
}
