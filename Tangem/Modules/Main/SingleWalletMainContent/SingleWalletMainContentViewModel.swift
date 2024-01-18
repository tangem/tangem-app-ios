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

    // MARK: - Dependencies

    private let userWalletNotificationManager: NotificationManager
    private let rateAppService: RateAppService

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
        delegate: SingleWalletMainContentDelegate?
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.delegate = delegate
        rateAppService = CommonRateAppService()

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
