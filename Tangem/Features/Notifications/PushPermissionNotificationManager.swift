//
//  PushPermissionNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PushPermissionNotificationDelegate: AnyObject {
    func showPushPermissionNotification(input: NotificationViewInput)
}

protocol PushPermissionNotificationManager: AnyObject {
    func showPushPermissionNotificationIfNeeded()
}

/// Aggregate logic support push permission notification in one union structure
final class CommonPushPermissionNotificationManager: PushPermissionNotificationManager {
    // MARK: Injected

    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    // MARK: - Private Properties

    private weak var displayDelegate: PushPermissionNotificationDelegate?
    private weak var notificationTapDelegate: NotificationTapDelegate?

    private let factory = PushNotificationsHelpersFactory()

    private lazy var permissionManager: PushNotificationsPermissionManager = factory.makePermissionManagerForAfterLoginBanner(using: pushNotificationsInteractor)

    private lazy var pushNotificationsAvailabilityProvider = factory.makeAvailabilityProviderForAfterLoginBanner(using: pushNotificationsInteractor)

    private var prepareNotificationTask: Task<Void, Never>?

    // MARK: - Init

    init(displayDelegate: PushPermissionNotificationDelegate?, notificationTapDelegate: NotificationTapDelegate?) {
        self.displayDelegate = displayDelegate
        self.notificationTapDelegate = notificationTapDelegate
    }

    // MARK: - Public Implementation

    func showPushPermissionNotificationIfNeeded() {
        prepareNotificationTask?.cancel()

        prepareNotificationTask = runTask(in: self) { @MainActor manager in
            await manager.prepareAndDisplayNotification()
        }
    }

    // MARK: - Private Implementation

    private func prepareAndDisplayNotification() async {
        guard pushNotificationsAvailabilityProvider.isAvailable else {
            return
        }

        let buttonActionYes: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            runTask(in: self) { @MainActor manager in
                await manager.permissionManager.allowPermissionRequest()
                manager.notificationTapDelegate?.didTapNotification(with: id, action: action)
            }
        }

        let buttonActionNo: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            permissionManager.postponePermissionRequest()
            notificationTapDelegate?.didTapNotification(with: id, action: action)
        }

        let input = NotificationViewInput(
            style: .withButtons([
                NotificationView.NotificationButton(
                    action: buttonActionNo,
                    actionType: .postponePushPermissionRequest,
                    isWithLoader: false
                ),
                NotificationView.NotificationButton(
                    action: buttonActionYes,
                    actionType: .allowPushPermissionRequest,
                    isWithLoader: false
                ),
            ]),
            severity: .info,
            settings: .init(
                event: GeneralNotificationEvent.pushNotificationsPermissionRequest,
                dismissAction: { [weak self] _ in
                    guard let self else { return }
                    saveDisplayNotificationDate()
                    permissionManager.postponePermissionRequest()
                }
            )
        )

        displayDelegate?.showPushPermissionNotification(input: input)
    }

    private func saveDisplayNotificationDate() {
        AppSettings.shared.supportSeedNotificationShownDate = Date()
    }
}
