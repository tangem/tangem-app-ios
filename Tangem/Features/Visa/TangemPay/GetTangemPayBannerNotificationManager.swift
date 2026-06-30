//
//  GetTangemPayBannerNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

final class GetTangemPayBannerNotificationManager {
    typealias TapAction = (TangemPayWalletSelectionType) -> Void

    private let tapAction: TapAction

    @Injected(\.tangemPayAvailabilityRepository)
    private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var cancellable: Cancellable?

    init(userWalletId: String, tapAction: @escaping TapAction) {
        self.tapAction = tapAction

        cancellable = tangemPayAvailabilityRepository
            .tangemPayBannerEntrypointEligibleWalletSelectionPublisher(for: userWalletId)
            .withWeakCaptureOf(self)
            .map { manager, availableSelection -> [NotificationViewInput] in
                guard let availableSelection else { return [] }
                return [manager.makeNotificationInput(availableSelection: availableSelection)]
            }
            .sink(receiveValue: notificationInputsSubject.send)
    }

    private func makeNotificationInput(
        availableSelection: TangemPayWalletSelectionType
    ) -> NotificationViewInput {
        let event = GetTangemPayBannerNotificationEvent()

        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self, tapAction] id, actionType in
            switch actionType {
            case .closeGetTangemPay:
                self?.dismissNotification(with: id)
            case .openGetTangemPay:
                tapAction(availableSelection)
            default:
                break
            }
        }

        return NotificationViewInput(
            style: .withButtons([
                .init(action: buttonAction, actionType: .closeGetTangemPay, isWithLoader: false),
                .init(action: buttonAction, actionType: .openGetTangemPay, isWithLoader: false),
            ]),
            severity: event.severity,
            settings: .init(
                event: event,
                dismissAction: { [weak self] _ in
                    self?.tangemPayAvailabilityRepository.userDidCloseGetTangemPayBanner()
                }
            )
        )
    }
}

// MARK: - NotificationManager

extension GetTangemPayBannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: (any NotificationTapDelegate)?) {
        // Tap routes via the closure injected on init; no delegate needed.
    }

    func dismissNotification(with id: NotificationViewId) {
        tangemPayAvailabilityRepository.userDidCloseGetTangemPayBanner()
    }
}
