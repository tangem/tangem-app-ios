//
//  SupportSeedNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

protocol SupportSeedNotificationDelegate: AnyObject {
    func showSupportSeedNotification(input: NotificationViewInput)
}

protocol SupportSeedNotificationManager: AnyObject {
    func showSupportSeedNotificationIfNeeded()
}

// Agregate logic support seed notification in one union structure
final class CommonSupportSeedNotificationManager: SupportSeedNotificationManager {
    // MARK: Injected

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private weak var notificationTapDelegate: NotificationTapDelegate?
    private weak var displayDelegate: SupportSeedNotificationDelegate?

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        displayDelegate: SupportSeedNotificationDelegate,
        notificationTapDelegate: NotificationTapDelegate?
    ) {
        self.userWalletId = userWalletId
        self.displayDelegate = displayDelegate
        self.notificationTapDelegate = notificationTapDelegate
    }

    // MARK: - Public Implementation

    func showSupportSeedNotificationIfNeeded() {
        TangemFoundation.runTask(in: self) { manager in
            do {
                let status = try await manager.tangemApiService.getSeedNotifyStatus(
                    userWalletId: manager.userWalletId.stringValue
                ).status

                TangemFoundation.runTask(in: self) { @MainActor manager in
                    switch status {
                    case .confirmed:
                        if let shownDate = AppSettings.shared.supportSeedNotificationShownDate,
                           Date().timeIntervalSince(shownDate) > Constants.durationDisplayNotification {
                            manager.showConfirmedSupportSeedNotification()
                        }
                    case .declined, .notNeeded, .accepted, .rejected:
                        break
                    case .notified:
                        manager.showSupportSeedNotification()
                    }
                }
            } catch {
                if case .statusCode(let response) = error as? MoyaError,
                   response.statusCode == 404 {
                    manager.showSupportSeedNotification()
                    try? await manager.tangemApiService.setSeedNotifyStatus(
                        userWalletId: manager.userWalletId.stringValue,
                        status: .notified
                    )
                }
            }
        }
    }

    // MARK: - Private Implementation

    private func showSupportSeedNotification() {
        let buttonActionYes: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            Analytics.log(.mainNoticeSeedSupportButtonYes)
            notificationTapDelegate?.didTapNotification(with: id, action: action)

            TangemFoundation.runTask(in: self) { manager in
                try? await manager.tangemApiService.setSeedNotifyStatus(
                    userWalletId: manager.userWalletId.stringValue,
                    status: .confirmed
                )
            }
        }

        let buttonActionNo: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            Analytics.log(.mainNoticeSeedSupportButtonNo)
            notificationTapDelegate?.didTapNotification(with: id, action: action)

            TangemFoundation.runTask(in: self) { manager in
                try? await manager.tangemApiService.setSeedNotifyStatus(
                    userWalletId: manager.userWalletId.stringValue,
                    status: .declined
                )
            }
        }

        let input = NotificationViewInput(
            style: .withButtons([
                NotificationView.NotificationButton(
                    action: buttonActionNo,
                    actionType: .seedSupportNo,
                    isWithLoader: false
                ),
                NotificationView.NotificationButton(
                    action: buttonActionYes,
                    actionType: .seedSupportYes,
                    isWithLoader: false
                ),
            ]),
            severity: .critical,
            settings: .init(event: GeneralNotificationEvent.seedSupport, dismissAction: nil)
        )

        AppSettings.shared.supportSeedNotificationShownDate = Date()

        displayDelegate?.showSupportSeedNotification(input: input)
    }

    private func showConfirmedSupportSeedNotification() {
        let buttonActionYes: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            Analytics.log(.mainNoticeSeedSupportButtonUsed)
            notificationTapDelegate?.didTapNotification(with: id, action: action)

            TangemFoundation.runTask(in: self) { manager in
                try? await manager.tangemApiService.setSeedNotifyStatusConfirmed(
                    userWalletId: manager.userWalletId.stringValue,
                    status: .accepted
                )
            }
        }

        let buttonActionNo: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            guard let self else { return }

            Analytics.log(.mainNoticeSeedSupportButtonDeclined)
            notificationTapDelegate?.didTapNotification(with: id, action: action)

            TangemFoundation.runTask(in: self) { manager in
                try? await manager.tangemApiService.setSeedNotifyStatusConfirmed(
                    userWalletId: manager.userWalletId.stringValue,
                    status: .rejected
                )
            }
        }

        let input = NotificationViewInput(
            style: .withButtons([
                NotificationView.NotificationButton(
                    action: buttonActionNo,
                    actionType: .seedSupport2No,
                    isWithLoader: false
                ),
                NotificationView.NotificationButton(
                    action: buttonActionYes,
                    actionType: .seedSupport2Yes,
                    isWithLoader: false
                ),
            ]),
            severity: .critical,
            settings: .init(event: GeneralNotificationEvent.seedSupport2, dismissAction: nil)
        )

        displayDelegate?.showSupportSeedNotification(input: input)
    }
}

private extension CommonSupportSeedNotificationManager {
    // MARK: - Constants

    enum Constants {
        /// One week
        static let durationDisplayNotification: TimeInterval = 7 * 24 * 60 * 60
    }
}
