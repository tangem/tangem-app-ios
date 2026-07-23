//
//  ForceUpdateBannerNotificationManager.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

// [REDACTED_TODO_COMMENT]

final class ForceUpdateBannerNotificationManager {
    @Injected(\.forceUpdateService) private var forceUpdateService: ForceUpdateService

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var bag = Set<AnyCancellable>()

    init() {
        bind()
    }

    private func bind() {
        forceUpdateService
            .statePublisher
            .map { $0.isOptionalUpdate }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { manager, shouldShow -> [NotificationViewInput] in
                guard shouldShow else { return [] }
                return [manager.makeNotificationInput()]
            }
            .receive(on: DispatchQueue.main)
            .subscribe(notificationInputsSubject)
            .store(in: &bag)
    }

    private func makeNotificationInput() -> NotificationViewInput {
        NotificationsFactory().buildNotificationInput(
            for: GeneralNotificationEvent.forceUpdateAvailable,
            action: { _ in },
            buttonAction: { _, actionType in
                if case .openAppStore = actionType {
                    AppStoreOpener.open()
                }
            },
            dismissAction: { _ in }
        )
    }
}

// MARK: - NotificationManager

extension ForceUpdateBannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    /// The soft-update banner is not user-dismissable (its event has `isDismissable == false`);
    /// it disappears only when the backend state stops reporting an optional update.
    func dismissNotification(with id: NotificationViewId) {}
}
