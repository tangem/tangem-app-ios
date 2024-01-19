//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class SingleWalletMainContentViewModel: SingleTokenBaseViewModel, ObservableObject {
    // MARK: - ViewState

    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var rateAppBottomSheetViewModel: RateAppBottomSheetViewModel?
    @Published var isAppStoreReviewRequested = false

    // MARK: - Dependencies

    private let userWalletNotificationManager: NotificationManager
    private unowned let coordinator: SingleWalletMainContentRoutable

    private let rateAppService = RateAppService()

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()

    private var updateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: SingleWalletMainContentDelegate?

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        userWalletNotificationManager: NotificationManager,
        tokenNotificationManager: NotificationManager,
        tokenRouter: SingleTokenRoutable,
        coordinator: SingleWalletMainContentRoutable,
        delegate: SingleWalletMainContentDelegate?
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.coordinator = coordinator
        self.delegate = delegate

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: tokenNotificationManager,
            tokenRouter: tokenRouter
        )

        bind()
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        delegate?.present(actionSheet: actionSheet)
    }

    private func bind() {
        let userWalletNotificationsPublisher = userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .share(replay: 1)

        userWalletNotificationsPublisher
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        userWalletModel
            .totalBalancePublisher
            .compactMap { $0.value }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                let walletModels = viewModel.userWalletModel.walletModelsManager.walletModels
                viewModel.rateAppService.registerBalances(of: walletModels)
            }
            .store(in: &bag)

        let isBalanceLoadedPublisher = userWalletModel
            .totalBalancePublisher
            .map { $0.value != nil }
            .removeDuplicates()

        Publishers.CombineLatest3(isPageSelectedSubject, isBalanceLoadedPublisher, userWalletNotificationsPublisher)
            .map { isPageSelected, isBalanceLoaded, notifications in
                return RateAppRequest(
                    isLocked: false,
                    isSelected: isPageSelected,
                    isBalanceLoaded: isBalanceLoaded,
                    displayedNotifications: notifications
                )
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, rateAppRequest in
                viewModel.rateAppService.requestRateAppIfAvailable(with: rateAppRequest)
            }
            .store(in: &bag)

        rateAppService
            .rateAppAction
            .withWeakCaptureOf(self)
            .sink { viewModel, rateAppAction in
                viewModel.handleRateAppAction(rateAppAction)
            }
            .store(in: &bag)
    }

    private func handleRateAppAction(_ action: RateAppAction) {
        rateAppBottomSheetViewModel = nil

        switch action {
        case .openAppRateDialog:
            rateAppBottomSheetViewModel = RateAppBottomSheetViewModel { [weak self] response in
                self?.rateAppService.respondToRateAppDialog(with: response)
            }
        case .openMailWithEmailType(let emailType):
            let userWallet = userWalletModel
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                let collector = NegativeFeedbackDataCollector(userWalletEmailData: userWallet.emailData)
                let recipient = userWallet.config.emailConfig?.recipient ?? EmailConfig.default.recipient
                self?.coordinator.openMail(with: collector, emailType: emailType, recipient: recipient)
            }
        case .openAppStoreReview:
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
                self?.isAppStoreReviewRequested = true
            }
        }
    }
}

// MARK: - MainViewPage protocol conformance

extension SingleWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}

// MARK: - Constants

private extension SingleWalletMainContentViewModel {
    private enum Constants {
        static let feedbackRequestDelay = 0.7
    }
}
