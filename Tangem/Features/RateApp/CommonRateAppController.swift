//
//  CommonRateAppController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// Narrows the app-global eligibility from `RateAppService` down to a single main screen page.
final class CommonRateAppController {
    @Injected(\.rateAppService) private var rateAppService: RateAppService

    private let userWalletModel: UserWalletModel
    private weak var coordinator: RateAppRoutable?

    /// The page is suppressed until `bind(...)` supplies its balance and notification state.
    private let isSuppressedSubject = CurrentValueSubject<Bool, Never>(true)

    private var bag: Set<AnyCancellable> = []

    private var isBalanceLoadedPublisher: AnyPublisher<Bool, Never> {
        userWalletModel
            .totalBalancePublisher
            .filter { !$0.isLoading }
            .map { $0.isLoaded }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(
        userWalletModel: UserWalletModel,
        coordinator: RateAppRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    private func bindSuppression(to notificationsPublisher: some Publisher<[NotificationViewInput], Never>) {
        isBalanceLoadedPublisher
            .combineLatest(notificationsPublisher)
            .map { isBalanceLoaded, notifications in
                !isBalanceLoaded || notifications.contains { Constants.suppressingSeverityLevels.contains($0.severity) }
            }
            .removeDuplicates()
            .receiveOnMain()
            .subscribe(isSuppressedSubject)
            .store(in: &bag)

        userWalletModel
            .totalBalancePublisher
            .filter { $0.isLoaded }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { controller, _ in
                let walletModels = AccountWalletModelsAggregator.walletModels(from: controller.userWalletModel.accountModelsManager)
                controller.rateAppService.registerBalances(of: walletModels)
            }
            .store(in: &bag)
    }

    /// The prompt is still animating away when the response arrives, so the destination is opened after it settles.
    private func afterDismissAnimation(_ action: @MainActor @escaping (CommonRateAppController) -> Void) {
        Task { @MainActor [weak self] in
            try? await ContinuousClock().sleep(for: .seconds(Constants.feedbackRequestDelay))

            guard let self else {
                return
            }

            action(self)
        }
    }
}

// MARK: - RateAppInteractionController protocol conformance

extension CommonRateAppController: RateAppInteractionController {
    func bind(
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    ) {
        bindSuppression(
            to: notificationsPublisher1
                .combineLatest(notificationsPublisher2)
                .map { $0 + $1 }
        )
    }

    func bind(notificationsPublisher: some Publisher<[NotificationViewInput], Never>) {
        bindSuppression(to: notificationsPublisher)
    }

    func openFeedbackMail() {
        rateAppService.respondToRateAppDialog(with: .negative)

        afterDismissAnimation { controller in
            let userWalletModel = controller.userWalletModel
            let collector = NegativeFeedbackDataCollector(userWalletEmailData: userWalletModel.emailData)
            let recipient = userWalletModel.config.emailConfig?.recipient ?? EmailConfig.default.recipient
            controller.coordinator?.openMail(with: collector, emailType: .negativeRateAppFeedback, recipient: recipient)
        }
    }

    func openAppStoreReview() {
        rateAppService.respondToRateAppDialog(with: .positive)

        afterDismissAnimation { controller in
            controller.coordinator?.openAppStoreReview()
        }
    }
}

// MARK: - RateAppNotificationController protocol conformance

extension CommonRateAppController: RateAppNotificationController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> {
        rateAppService
            .isEligiblePublisher
            .combineLatest(isSuppressedSubject)
            .map { isEligible, isSuppressed in isEligible && !isSuppressed }
            .removeDuplicates()
            .receiveOnMain()
            .eraseToAnyPublisher()
    }

    func dismissAppRate() {
        rateAppService.respondToRateAppDialog(with: .dismissed)
    }
}

// MARK: - Constants

private extension CommonRateAppController {
    enum Constants {
        static let feedbackRequestDelay = 0.7

        /// A page showing a problem the user has to deal with is a bad place to ask for a review.
        static let suppressingSeverityLevels: Set<NotificationView.Severity> = [
            .warning,
            .critical,
        ]
    }
}
