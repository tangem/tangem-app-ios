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

final class CommonRateAppController {
    private let rateAppService: RateAppService
    private let userWalletModel: UserWalletModel
    private weak var coordinator: RateAppRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        rateAppService: RateAppService,
        userWalletModel: UserWalletModel,
        coordinator: RateAppRoutable?
    ) {
        self.rateAppService = rateAppService
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    private func handleRateAppAction(_ action: RateAppAction) {
        switch action {
        case .openFeedbackMailWithEmailType(let emailType):
            let userWallet = userWalletModel
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                let collector = NegativeFeedbackDataCollector(userWalletEmailData: userWallet.emailData)
                let recipient = userWallet.config.emailConfig?.recipient ?? EmailConfig.default.recipient
                self?.coordinator?.openFeedbackMail(with: collector, emailType: emailType, recipient: recipient)
            }
        case .openAppStoreReview:
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                self?.coordinator?.openAppStoreReview()
            }
        }
    }
}

// MARK: - RateAppController protocol conformance

extension CommonRateAppController: RateAppController {
    private var isBalanceLoadedPublisher: AnyPublisher<Bool, Never> {
        userWalletModel
            .totalBalancePublisher
            .map { $0.value != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    ) {
        isPageSelectedPublisher.combineLatest(isBalanceLoadedPublisher, notificationsPublisher1, notificationsPublisher2)
            .withWeakCaptureOf(self)
            .sink { controller, values in
                controller.request(isPageSelected: values.0, isBalanceLoaded: values.1, notifications: values.2 + values.3)
            }
            .store(in: &bag)

        bind()
    }

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    ) {
        isPageSelectedPublisher.combineLatest(isBalanceLoadedPublisher, notificationsPublisher)
            .withWeakCaptureOf(self)
            .sink { controller, values in
                controller.request(isPageSelected: values.0, isBalanceLoaded: values.1, notifications: values.2)
            }
            .store(in: &bag)

        bind()
    }

    private func bind() {
        userWalletModel
            .totalBalancePublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .sink { controller, _ in
                let walletModels = controller.userWalletModel.walletModelsManager.walletModels
                controller.rateAppService.registerBalances(of: walletModels)
            }
            .store(in: &bag)

        rateAppService
            .rateAppAction
            .withWeakCaptureOf(self)
            .sink { controller, rateAppAction in
                controller.handleRateAppAction(rateAppAction)
            }
            .store(in: &bag)
    }

    private func request(isPageSelected: Bool, isBalanceLoaded: Bool, notifications: [NotificationViewInput]) {
        let rateAppRequest = RateAppRequest(
            isLocked: false,
            isSelected: isPageSelected,
            isBalanceLoaded: isBalanceLoaded,
            displayedNotifications: notifications
        )

        rateAppService.requestRateAppIfAvailable(with: rateAppRequest)
    }
}

// MARK: - Constants

private extension CommonRateAppController {
    private enum Constants {
        static let feedbackRequestDelay = 0.7
    }
}
